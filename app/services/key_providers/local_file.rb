require "openssl"
require "json"
require "base64"
require_relative "../crypto/error"
require_relative "../crypto/unknown_key_error"
require_relative "../crypto/key_wrap_error"
require_relative "../crypto/key_unwrap_error"

module KeyProviders
  class LocalFile < Base
    PROVIDER_NAME = "local_file"
    WRAP_VERSION = 1
    WRAP_ALGORITHM = "A256GCM"

    def initialize(key_dir:, active_key_id:)
      @key_dir = File.expand_path(key_dir)
      @active_key_id = active_key_id.to_s
      raise ArgumentError, "active_key_id is required" if @active_key_id.empty?
    end

    attr_reader :active_key_id

    def provider_name = PROVIDER_NAME

    def verify_key!(key_id = active_key_id)
      key = read_kek(key_id)
      true
    ensure
      key = nil
    end

    def wrap_key(dek:, context:)
      raise Crypto::KeyWrapError, "DEK must be 32 bytes" unless dek&.bytesize == 32
      kek_id = active_key_id
      kek = read_kek(kek_id)
      nonce = OpenSSL::Random.random_bytes(12)
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = kek
      cipher.iv = nonce
      cipher.auth_data = wrap_aad(kek_id, context)
      ciphertext = cipher.update(dek) + cipher.final
      tag = cipher.auth_tag(16)

      JSON.generate(
        "v" => WRAP_VERSION,
        "alg" => WRAP_ALGORITHM,
        "kid" => kek_id,
        "iv" => b64(nonce),
        "tag" => b64(tag),
        "ct" => b64(ciphertext)
      ).b
    rescue Crypto::Error
      raise
    rescue StandardError => e
      raise Crypto::KeyWrapError, "failed to wrap DEK: #{e.class}"
    end

    def unwrap_key(wrapped_key:, key_id:, context:)
      data = JSON.parse(wrapped_key)
      validate_blob!(data, key_id)
      nonce = b64d(data.fetch("iv"))
      tag = b64d(data.fetch("tag"))
      ciphertext = b64d(data.fetch("ct"))
      raise Crypto::KeyUnwrapError, "invalid wrapping nonce" unless nonce.bytesize == 12
      raise Crypto::KeyUnwrapError, "invalid wrapping tag" unless tag.bytesize == 16

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = read_kek(key_id)
      cipher.iv = nonce
      cipher.auth_tag = tag
      cipher.auth_data = wrap_aad(key_id, context)
      dek = cipher.update(ciphertext) + cipher.final
      raise Crypto::KeyUnwrapError, "invalid unwrapped DEK length" unless dek.bytesize == 32
      dek
    rescue Crypto::Error
      raise
    rescue OpenSSL::Cipher::CipherError
      raise Crypto::KeyUnwrapError, "wrapped DEK authentication failed"
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Crypto::KeyUnwrapError, "malformed wrapped DEK"
    rescue StandardError => e
      raise Crypto::KeyUnwrapError, "failed to unwrap DEK: #{e.class}"
    end

    private

    def read_kek(key_id)
      id = key_id.to_s
      unless id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}\z/)
        raise Crypto::UnknownKeyError, "invalid KEK id"
      end

      path = File.join(@key_dir, "#{id}.key")
      raise Crypto::UnknownKeyError, "KEK not found: #{id}" unless File.file?(path)
      key = File.binread(path)
      raise Crypto::UnknownKeyError, "KEK #{id} must be exactly 32 bytes" unless key.bytesize == 32
      key
    end

    def wrap_aad(key_id, context)
      required = %i[user_id vault_item_id vault_item_version_id]
      missing = required.reject { |key| context[key] && !context[key].to_s.empty? }
      raise ArgumentError, "missing wrap context: #{missing.join(', ')}" if missing.any?

      [
        "ruby-envelope-vault-key-wrap",
        "v=#{WRAP_VERSION}",
        "provider=#{PROVIDER_NAME}",
        "kid=#{key_id}",
        "u=#{context.fetch(:user_id)}",
        "i=#{context.fetch(:vault_item_id)}",
        "r=#{context.fetch(:vault_item_version_id)}"
      ].join("|")
    end

    def validate_blob!(data, requested_key_id)
      raise Crypto::KeyUnwrapError, "unsupported wrapped-key version" unless data["v"] == WRAP_VERSION
      raise Crypto::KeyUnwrapError, "unsupported wrapped-key algorithm" unless data["alg"] == WRAP_ALGORITHM
      raise Crypto::KeyUnwrapError, "wrapped-key id mismatch" unless data["kid"] == requested_key_id.to_s
    end

    def b64(bytes) = Base64.urlsafe_encode64(bytes, padding: false)
    def b64d(value) = Base64.urlsafe_decode64(value.to_s)
  end
end
