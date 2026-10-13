require "test_helper"
require_relative "../../../app/services/key_providers/registry"

class RegistryWriteGuardTest < ActiveSupport::TestCase
  setup do
    @vault = Rails.configuration.x.vault
    @previous = {
      key_provider: @vault.key_provider,
      active_kek_id: @vault.active_kek_id,
      aws_region: @vault.aws_region
    }

    @vault.key_provider = "aws_kms"
    @vault.aws_region = "ap-southeast-1"
    KeyRegistry.where(provider: "aws_kms").delete_all
  end

  teardown do
    @vault.key_provider = @previous[:key_provider]
    @vault.active_kek_id = @previous[:active_kek_id]
    @vault.aws_region = @previous[:aws_region]
  end

  test "registry aws provider allows writes when configured key matches active row" do
    @vault.active_kek_id = "key-active"
    KeyRegistry.create!(
      provider: "aws_kms",
      kek_id: "key-active",
      status: "active",
      activated_at: Time.current
    )

    provider = with_fake_aws_client { KeyProviders::Registry.fetch }

    assert provider.assert_write_allowed!
  end

  test "registry aws provider blocks writes when configured key is decrypt only" do
    @vault.active_kek_id = "key-old"
    KeyRegistry.create!(provider: "aws_kms", kek_id: "key-old", status: "decrypt_only")
    KeyRegistry.create!(
      provider: "aws_kms",
      kek_id: "key-new",
      status: "active",
      activated_at: Time.current
    )

    provider = with_fake_aws_client { KeyProviders::Registry.fetch }

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      provider.assert_write_allowed!
    end

    assert_equal "AWS KMS configured active key does not match KeyRegistry", error.message
    refute_includes error.message, "key-old"
    refute_includes error.message, "key-new"
  end

  private

  def with_fake_aws_client
    fake_client = Object.new
    singleton = KeyProviders::AwsKmsClient.singleton_class
    singleton.alias_method :new_without_write_guard_test, :new
    singleton.define_method(:new) { |**_args| fake_client }
    yield
  ensure
    if defined?(singleton) && singleton&.method_defined?(:new_without_write_guard_test)
      singleton.alias_method :new, :new_without_write_guard_test
      singleton.remove_method :new_without_write_guard_test
    end
  end
end
