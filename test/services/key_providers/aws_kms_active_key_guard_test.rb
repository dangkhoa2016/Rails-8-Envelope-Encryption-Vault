require "test_helper"
require_relative "../../../app/services/key_providers/aws_kms_active_key_guard"

class AwsKmsActiveKeyGuardTest < ActiveSupport::TestCase
  setup do
    KeyRegistry.where(provider: "aws_kms").delete_all
  end

  test "allows writes when configured key is the unique active registry key" do
    create_registry("key-active", "active")

    assert KeyProviders::AwsKmsActiveKeyGuard.verify!("key-active")
  end

  test "fails closed when configured key does not match active registry key" do
    create_registry("key-old", "decrypt_only")
    create_registry("key-new", "active")

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::AwsKmsActiveKeyGuard.verify!("key-old")
    end

    assert_equal "AWS KMS configured active key does not match KeyRegistry", error.message
    refute_includes error.message, "key-old"
    refute_includes error.message, "key-new"
  end

  test "fails closed when no active registry key exists" do
    create_registry("key-old", "decrypt_only")

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::AwsKmsActiveKeyGuard.verify!("key-old")
    end

    assert_equal "AWS KMS KeyRegistry must contain exactly one active key", error.message
  end

  test "fails closed when multiple active registry keys exist" do
    create_registry("key-a", "active")
    create_registry("key-b", "active")

    error = assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::AwsKmsActiveKeyGuard.verify!("key-a")
    end

    assert_equal "AWS KMS KeyRegistry must contain exactly one active key", error.message
  end

  private

  def create_registry(kek_id, status)
    KeyRegistry.create!(
      provider: "aws_kms",
      kek_id: kek_id,
      status: status,
      activated_at: status == "active" ? Time.current : nil
    )
  end
end
