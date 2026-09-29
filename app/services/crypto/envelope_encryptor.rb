require "openssl"
require_relative "authentication_error"
require_relative "unknown_key_provider_error"
require_relative "aad_builder"
require_relative "envelope"

module Crypto
  class EnvelopeEncryptor
    ENVELOPE_VERSION = 1
    AAD_VERSION = 1
    PAYLOAD_FORMAT = "json.v1"
    CIPHER_SUITE = "AES-256-GCM"

    def self.encrypt(plaintext:, context:, key_provider:)
      plaintext = String(plaintext).b
      raise ArgumentError, "plaintext cannot be empty" if plaintext.empty?

      key_provider.assert_write_allowed!

      dek = OpenSSL::Random.random_bytes(32)
      nonce = OpenSSL::Random.random_bytes(12)
      aad = build_aad(context)

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = dek
      cipher.iv = nonce
      cipher.auth_data = aad
      ciphertext = cipher.update(plaintext) + cipher.final
      tag = cipher.auth_tag(16)

      wrapped_dek = key_provider.wrap_key(dek: dek, context: context)

      Envelope.new(
        envelope_version: ENVELOPE_VERSION,
        payload_format: PAYLOAD_FORMAT,
        cipher_suite: CIPHER_SUITE,
        ciphertext: ciphertext,
        nonce: nonce,
        authentication_tag: tag,
        key_provider: key_provider.provider_name,
        kek_id: key_provider.active_key_id,
        wrapped_dek: wrapped_dek,
        aad_version: AAD_VERSION
      )
    ensure
      dek = nil
    end

    def self.decrypt(envelope:, context:, key_provider:)
      unless envelope.key_provider == key_provider.provider_name
        raise Crypto::UnknownKeyProviderError, "envelope provider mismatch"
      end

      dek = key_provider.unwrap_key(
        wrapped_key: envelope.wrapped_dek,
        key_id: envelope.kek_id,
        context: context
      )

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = dek
      cipher.iv = envelope.nonce
      cipher.auth_tag = envelope.authentication_tag
      cipher.auth_data = build_aad(context, envelope: envelope)
      cipher.update(envelope.ciphertext) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      raise Crypto::AuthenticationError, "ciphertext authentication failed"
    ensure
      dek = nil
    end

    def self.build_aad(context, envelope: nil)
      AadBuilder.call(
        envelope_version: envelope&.envelope_version || ENVELOPE_VERSION,
        aad_version: envelope&.aad_version || AAD_VERSION,
        user_id: context.fetch(:user_id),
        vault_item_id: context.fetch(:vault_item_id),
        vault_item_version_id: context.fetch(:vault_item_version_id)
      )
    end
    private_class_method :build_aad
  end
end
