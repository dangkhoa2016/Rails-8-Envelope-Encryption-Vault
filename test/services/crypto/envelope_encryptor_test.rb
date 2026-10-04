require_relative "../../crypto_test_helper"

class EnvelopeEncryptorTest < Minitest::Test
  include CryptoTestSupport

  def test_round_trip_unicode_payload
    with_provider do |provider|
      plaintext = Crypto::PayloadSerializer.dump("schema" => "vault.secure_note.v1", "title" => "Ghi chú", "body" => "bí mật 🔐")
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: plaintext, context: context, key_provider: provider)
      recovered = Crypto::EnvelopeEncryptor.decrypt(envelope: envelope, context: context, key_provider: provider)
      assert_equal Crypto::PayloadSerializer.load(plaintext), Crypto::PayloadSerializer.load(recovered)
    end
  end

  def test_same_plaintext_twice_produces_different_ciphertext
    with_provider do |provider|
      a = Crypto::EnvelopeEncryptor.encrypt(plaintext: "same", context: context, key_provider: provider)
      b = Crypto::EnvelopeEncryptor.encrypt(plaintext: "same", context: context, key_provider: provider)
      refute_equal a.ciphertext, b.ciphertext
      refute_equal a.nonce, b.nonce
      refute_equal a.wrapped_dek, b.wrapped_dek
    end
  end

  def test_tampered_ciphertext_fails
    with_provider do |provider|
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "secret", context: context, key_provider: provider)
      tampered = envelope.to_h
      tampered[:ciphertext] = envelope.ciphertext.dup.tap { |s| s.setbyte(0, s.getbyte(0) ^ 0x01) }
      assert_raises(Crypto::AuthenticationError) do
        Crypto::EnvelopeEncryptor.decrypt(envelope: Crypto::Envelope.new(**tampered), context: context, key_provider: provider)
      end
    end
  end

  def test_tampered_tag_fails
    with_provider do |provider|
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "secret", context: context, key_provider: provider)
      tampered = envelope.to_h
      tampered[:authentication_tag] = envelope.authentication_tag.dup.tap { |s| s.setbyte(0, s.getbyte(0) ^ 0x01) }
      assert_raises(Crypto::AuthenticationError) do
        Crypto::EnvelopeEncryptor.decrypt(envelope: Crypto::Envelope.new(**tampered), context: context, key_provider: provider)
      end
    end
  end

  def test_wrong_aad_fails
    with_provider do |provider|
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "secret", context: context, key_provider: provider)
      wrong = context.merge(user_id: SecureRandom.uuid)
      assert_raises(Crypto::KeyUnwrapError) do
        Crypto::EnvelopeEncryptor.decrypt(envelope: envelope, context: wrong, key_provider: provider)
      end
    end
  end

  def test_tampered_nonce_fails
    with_provider do |provider|
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "secret", context: context, key_provider: provider)
      attrs = envelope.to_h
      attrs[:nonce] = envelope.nonce.dup.tap { |value| value.setbyte(0, value.getbyte(0) ^ 0x01) }
      assert_raises(Crypto::AuthenticationError) do
        Crypto::EnvelopeEncryptor.decrypt(envelope: Crypto::Envelope.new(**attrs), context: context, key_provider: provider)
      end
    end
  end

  def test_truncated_tag_is_rejected
    with_provider do |provider|
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "secret", context: context, key_provider: provider)
      attrs = envelope.to_h.merge(authentication_tag: envelope.authentication_tag.byteslice(0, 15))
      assert_raises(Crypto::InvalidEnvelopeError) { Crypto::Envelope.new(**attrs) }
    end
  end
end
