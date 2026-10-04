require_relative "../../crypto_test_helper"
require_relative "../../../app/services/key_providers/external_kms"
require_relative "../../support/fake_kms_client"

class ExternalKmsKeyProviderTest < Minitest::Test
  def setup
    @key_id = "kms-key-01"
    @keys = { @key_id => OpenSSL::Random.random_bytes(32) }
    @client = TestSupport::FakeKmsClient.new(keys: @keys)
    @provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: @key_id,
      client: @client
    )
    @context = {
      user_id: SecureRandom.uuid,
      vault_item_id: SecureRandom.uuid,
      vault_item_version_id: SecureRandom.uuid
    }
  end

  def test_declares_expected_capabilities
    capabilities = @provider.capabilities

    assert_equal true, capabilities[:remote_kek]
    assert_equal true, capabilities[:opaque_wrapped_dek]
    assert_equal true, capabilities[:encryption_context]
    assert_equal false, capabilities[:local_kek_export]
  end

  def test_wrap_unwrap_round_trip_and_verify_key
    dek = OpenSSL::Random.random_bytes(32)
    wrapped = @provider.wrap_key(dek: dek, context: @context)

    assert @provider.verify_key!
    assert_equal dek, @provider.unwrap_key(wrapped_key: wrapped, key_id: @key_id, context: @context)
    refute_includes wrapped, dek
  end

  def test_wrong_key_id_is_rejected
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)

    assert_raises(Crypto::KeyUnwrapError) do
      @provider.unwrap_key(wrapped_key: wrapped, key_id: "wrong-key", context: @context)
    end
  end

  def test_wrong_context_is_rejected
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)
    wrong_context = @context.merge(vault_item_version_id: SecureRandom.uuid)

    assert_raises(Crypto::KeyProviderUnavailableError) do
      @provider.unwrap_key(wrapped_key: wrapped, key_id: @key_id, context: wrong_context)
    end
  end

  def test_missing_configuration_is_rejected
    assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::ExternalKms.new(provider_name: "", active_key_id: @key_id, client: @client)
    end

    assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::ExternalKms.new(provider_name: "x", active_key_id: "", client: @client)
    end

    assert_raises(Crypto::KeyProviderConfigurationError) do
      KeyProviders::ExternalKms.new(provider_name: "x", active_key_id: @key_id, client: nil)
    end
  end

  def test_missing_remote_key_is_reported_without_client_detail
    error = assert_raises(Crypto::UnknownKeyError) do
      @provider.verify_key!("missing-key")
    end

    assert_equal "KMS key unavailable", error.message
  end

  def test_client_failure_maps_to_generic_unavailable_error
    failing_client = Object.new
    def failing_client.key_available?(key_id:) = raise("credential/token detail")
    provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: @key_id,
      client: failing_client
    )

    error = assert_raises(Crypto::KeyProviderUnavailableError) { provider.verify_key! }
    refute_includes error.message, "credential"
    refute_includes error.message, "token"
  end

  def test_wrap_failure_does_not_leak_expired_credential_detail
    failing_client = Object.new
    def failing_client.key_available?(key_id:) = true
    def failing_client.encrypt(**_params) = raise("ExpiredToken AKIA-PRIVATE credential detail")

    provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: @key_id,
      client: failing_client
    )

    error = assert_raises(Crypto::KeyProviderUnavailableError) do
      provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)
    end

    assert_equal "KMS wrap unavailable", error.message
    refute_includes error.message, "ExpiredToken"
    refute_includes error.message, "AKIA"
  end

  def test_unwrap_failure_does_not_leak_access_denied_detail
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)
    failing_client = Object.new
    def failing_client.decrypt(**_params) = raise("AccessDenied arn:aws:kms:region:account:key/private")

    provider = KeyProviders::ExternalKms.new(
      provider_name: "external_kms_test",
      active_key_id: @key_id,
      client: failing_client
    )

    error = assert_raises(Crypto::KeyProviderUnavailableError) do
      provider.unwrap_key(wrapped_key: wrapped, key_id: @key_id, context: @context)
    end

    assert_equal "KMS unwrap unavailable", error.message
    refute_includes error.message, "AccessDenied"
    refute_includes error.message, "arn:aws:kms"
  end
end
