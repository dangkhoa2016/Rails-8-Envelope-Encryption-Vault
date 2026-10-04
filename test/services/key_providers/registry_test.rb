require "test_helper"
require_relative "../../../app/services/key_providers/registry"

class KeyProvidersRegistryTest < ActiveSupport::TestCase
  def setup
    @vault = Rails.configuration.x.vault
    @previous = {
      key_provider: @vault.key_provider,
      active_kek_id: @vault.active_kek_id,
      kek_dir: @vault.kek_dir,
      aws_region: @vault.aws_region
    }
  end

  def teardown
    @vault.key_provider = @previous[:key_provider]
    @vault.active_kek_id = @previous[:active_kek_id]
    @vault.kek_dir = @previous[:kek_dir]
    @vault.aws_region = @previous[:aws_region]
  end

  test "local_file remains the default provider" do
    @vault.key_provider = "local_file"

    provider = KeyProviders::Registry.fetch

    assert_instance_of KeyProviders::LocalFile, provider
  end
  test "unknown provider fails closed" do
    @vault.key_provider = "not-real"

    assert_raises(Crypto::UnknownKeyProviderError) do
      KeyProviders::Registry.fetch
    end
  end

  test "aws_kms requires a region" do
    @vault.key_provider = "aws_kms"
    @vault.active_kek_id = "key-02"
    @vault.aws_region = nil

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::Registry.fetch
    end

    assert_equal "AWS KMS region is required", error.message
  end

  test "aws_kms requires an active key id" do
    @vault.key_provider = "aws_kms"
    @vault.active_kek_id = ""
    @vault.aws_region = "ap-southeast-1"

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::Registry.fetch
    end

    assert_equal "AWS KMS active key id is required", error.message
  end
  test "aws_kms builds an external provider with the configured key" do
    @vault.key_provider = "aws_kms"
    @vault.active_kek_id = "key-02"
    @vault.aws_region = "ap-southeast-1"

    fake_client = Object.new
    singleton = KeyProviders::AwsKmsClient.singleton_class
    singleton.alias_method :new_without_registry_test, :new
    singleton.define_method(:new) { |**_args| fake_client }

    provider = KeyProviders::Registry.fetch

    assert_instance_of KeyProviders::ExternalKms, provider
    assert_equal "aws_kms", provider.provider_name
    assert_equal "key-02", provider.active_key_id
  ensure
    if defined?(singleton) && singleton&.method_defined?(:new_without_registry_test)
      singleton.alias_method :new, :new_without_registry_test
      singleton.remove_method :new_without_registry_test
    end
  end
end
