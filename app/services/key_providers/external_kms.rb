require "base64"
require "json"
require_relative "../crypto/key_provider_configuration_error"
require_relative "../crypto/key_provider_unavailable_error"

module KeyProviders
  class ExternalKms < Base
    WRAP_VERSION = 1

    def initialize(provider_name:, active_key_id:, client:, write_guard: nil)
      @provider_name = provider_name.to_s
      @active_key_id = active_key_id.to_s
      @client = client
      @write_guard = write_guard

      raise Crypto::KeyProviderConfigurationError, "provider_name is required" if @provider_name.empty?
      raise Crypto::KeyProviderConfigurationError, "active_key_id is required" if @active_key_id.empty?
      raise Crypto::KeyProviderConfigurationError, "client is required" unless @client
    end

    attr_reader :provider_name, :active_key_id

    def assert_write_allowed!
      @write_guard&.call(active_key_id)
      true
    end

    def capabilities
      {
        remote_kek: true,
        opaque_wrapped_dek: true,
        encryption_context: true,
        local_kek_export: false
      }.freeze
    end

    def verify_key!(key_id = active_key_id)
      available = @client.key_available?(key_id: key_id.to_s)
      raise Crypto::UnknownKeyError, "KMS key unavailable" unless available

      true
    rescue Crypto::Error
      raise
    rescue StandardError
      raise Crypto::KeyProviderUnavailableError, "KMS key verification unavailable"
    end

    def wrap_key(dek:, context:)
      raise Crypto::KeyWrapError, "DEK must be 32 bytes" unless dek&.bytesize == 32

      key_id = active_key_id
      verify_key!(key_id)
      ciphertext = @client.encrypt(
        key_id: key_id,
        plaintext: dek,
        encryption_context: normalized_context(context)
      )

      JSON.generate(
        "v" => WRAP_VERSION,
        "provider" => provider_name,
        "kid" => key_id,
        "ct" => Base64.strict_encode64(String(ciphertext).b)
      ).b
    rescue Crypto::Error
      raise
    rescue StandardError
      raise Crypto::KeyProviderUnavailableError, "KMS wrap unavailable"
    end

    def unwrap_key(wrapped_key:, key_id:, context:)
      data = JSON.parse(wrapped_key)
      validate_blob!(data, key_id)

      dek = @client.decrypt(
        key_id: key_id.to_s,
        ciphertext: Base64.strict_decode64(data.fetch("ct")),
        encryption_context: normalized_context(context)
      )

      raise Crypto::KeyUnwrapError, "invalid unwrapped DEK length" unless dek&.bytesize == 32

      dek
    rescue Crypto::Error
      raise
    rescue JSON::ParserError, KeyError, ArgumentError
      raise Crypto::KeyUnwrapError, "malformed KMS wrapped DEK"
    rescue StandardError
      raise Crypto::KeyProviderUnavailableError, "KMS unwrap unavailable"
    end

    private

    def validate_blob!(data, requested_key_id)
      raise Crypto::KeyUnwrapError, "unsupported KMS wrap version" unless data["v"] == WRAP_VERSION
      raise Crypto::KeyUnwrapError, "KMS provider mismatch" unless data["provider"] == provider_name
      raise Crypto::KeyUnwrapError, "KMS key id mismatch" unless data["kid"] == requested_key_id.to_s
    end

    def normalized_context(context)
      required = %i[user_id vault_item_id vault_item_version_id]
      values = required.to_h { |key| [ key.to_s, context.fetch(key).to_s ] }
      raise ArgumentError, "empty KMS encryption context" if values.values.any?(&:empty?)

      values.merge("purpose" => "ruby-envelope-vault-dek-wrap-v1")
    end
  end
end
