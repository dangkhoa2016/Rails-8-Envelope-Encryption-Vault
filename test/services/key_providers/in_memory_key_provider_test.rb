require_relative "../../crypto_test_helper"
require_relative "../../support/in_memory_key_provider"

class InMemoryKeyProviderTest < Minitest::Test
  def setup
    @old_id = "memory-old"
    @new_id = "memory-new"
    @provider = TestSupport::InMemoryKeyProvider.new(
      keys: {
        @old_id => OpenSSL::Random.random_bytes(32),
        @new_id => OpenSSL::Random.random_bytes(32)
      },
      active_key_id: @old_id
    )
    @context = {
      user_id: SecureRandom.uuid,
      vault_item_id: SecureRandom.uuid,
      vault_item_version_id: SecureRandom.uuid
    }
  end

  def test_wrap_unwrap_round_trip_and_verify_key
    dek = OpenSSL::Random.random_bytes(32)
    wrapped = @provider.wrap_key(dek: dek, context: @context)

    assert @provider.verify_key!(@old_id)
    assert_equal dek, @provider.unwrap_key(wrapped_key: wrapped, key_id: @old_id, context: @context)
  end

  def test_wrong_key_id_is_rejected
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)

    assert_raises(Crypto::KeyUnwrapError) do
      @provider.unwrap_key(wrapped_key: wrapped, key_id: @new_id, context: @context)
    end
  end

  def test_wrong_context_is_rejected
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)
    wrong_context = @context.merge(vault_item_version_id: SecureRandom.uuid)

    assert_raises(Crypto::KeyUnwrapError) do
      @provider.unwrap_key(wrapped_key: wrapped, key_id: @old_id, context: wrong_context)
    end
  end

  def test_tampered_wrapped_key_is_rejected
    wrapped = @provider.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: @context)
    data = JSON.parse(wrapped)
    ciphertext = Base64.urlsafe_decode64(data.fetch("ct"))
    ciphertext.setbyte(0, ciphertext.getbyte(0) ^ 0x01)
    data["ct"] = Base64.urlsafe_encode64(ciphertext, padding: false)

    assert_raises(Crypto::KeyUnwrapError) do
      @provider.unwrap_key(wrapped_key: JSON.generate(data), key_id: @old_id, context: @context)
    end
  end
end
