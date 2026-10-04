require "base64"
require "json"
require "openssl"

module TestSupport
  class InMemoryKeyProvider < KeyProviders::Base
    PROVIDER_NAME = "memory_test"
    WRAP_VERSION = 1
    WRAP_ALGORITHM = "A256GCM"

    attr_accessor :active_key_id

    def initialize(keys:, active_key_id:)
      @keys = keys.transform_keys(&:to_s)
      @active_key_id = active_key_id.to_s
      verify_key!
    end

    def provider_name = PROVIDER_NAME

    def verify_key!(key_id = active_key_id)
      key = @keys[key_id.to_s]
      raise Crypto::UnknownKeyError, "test KEK not found" unless key&.bytesize == 32

      true
    end

    def wrap_key(dek:, context:)
      raise Crypto::KeyWrapError, "DEK must be 32 bytes" unless dek&.bytesize == 32

      key_id = active_key_id
      key = fetch_key(key_id)
      nonce = OpenSSL::Random.random_bytes(12)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.auth_data = wrap_aad(key_id, context)
      ciphertext = cipher.update(dek) + cipher.final

      JSON.generate(
        "v" => WRAP_VERSION,
        "alg" => WRAP_ALGORITHM,
        "kid" => key_id,
        "iv" => encode(nonce),
        "tag" => encode(cipher.auth_tag(16)),
        "ct" => encode(ciphertext)
      ).b
    rescue Crypto::Error
      raise
    rescue StandardError => e
      raise Crypto::KeyWrapError, "test provider wrap failed: #{e.class}"
    end

    def unwrap_key(wrapped_key:, key_id:, context:)
      data = JSON.parse(wrapped_key)
      validate_blob!(data, key_id)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = fetch_key(key_id)
      cipher.iv = decode(data.fetch("iv"))
      cipher.auth_tag = decode(data.fetch("tag"))
      cipher.auth_data = wrap_aad(key_id, context)
      dek = cipher.update(decode(data.fetch("ct"))) + cipher.final
      raise Crypto::KeyUnwrapError, "invalid unwrapped DEK length" unless dek.bytesize == 32

      dek
    rescue Crypto::Error
      raise
    rescue OpenSSL::Cipher::CipherError
      raise Crypto::KeyUnwrapError, "test wrapped DEK authentication failed"
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Crypto::KeyUnwrapError, "malformed test wrapped DEK"
    end

    private

    def fetch_key(key_id)
      key = @keys[key_id.to_s]
      raise Crypto::UnknownKeyError, "test KEK not found" unless key&.bytesize == 32

      key
    end

    def validate_blob!(data, requested_key_id)
      raise Crypto::KeyUnwrapError, "unsupported test wrap version" unless data["v"] == WRAP_VERSION
      raise Crypto::KeyUnwrapError, "unsupported test wrap algorithm" unless data["alg"] == WRAP_ALGORITHM
      raise Crypto::KeyUnwrapError, "test wrapped-key id mismatch" unless data["kid"] == requested_key_id.to_s
    end

    def wrap_aad(key_id, context)
      required = %i[user_id vault_item_id vault_item_version_id]
      values = required.map { |key| context.fetch(key).to_s }
      raise ArgumentError, "empty test wrap context" if values.any?(&:empty?)

      [
        "ruby-envelope-vault-test-key-wrap",
        "v=#{WRAP_VERSION}",
        "provider=#{PROVIDER_NAME}",
        "kid=#{key_id}",
        *values
      ].join("|")
    end

    def encode(bytes) = Base64.urlsafe_encode64(bytes, padding: false)
    def decode(value) = Base64.urlsafe_decode64(value.to_s)
  end
end
