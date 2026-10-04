require_relative "../crypto/key_provider_configuration_error"
require_relative "../crypto/key_provider_unavailable_error"

module KeyProviders
  class AwsKmsActiveKeyGuard
    PROVIDER_NAME = "aws_kms"
    ACTIVE_STATUS = "active"

    def self.verify!(configured_key_id)
      key_id = configured_key_id.to_s
      if key_id.empty?
        raise Crypto::KeyProviderConfigurationError, "AWS KMS active key id is required"
      end

      active_key_ids = KeyRegistry
        .where(provider: PROVIDER_NAME, status: ACTIVE_STATUS)
        .limit(2)
        .pluck(:kek_id)

      unless active_key_ids.length == 1
        raise Crypto::KeyProviderConfigurationError,
          "AWS KMS KeyRegistry must contain exactly one active key"
      end

      unless active_key_ids.first == key_id
        raise Crypto::KeyProviderConfigurationError,
          "AWS KMS configured active key does not match KeyRegistry"
      end

      true
    rescue ActiveRecord::ActiveRecordError
      raise Crypto::KeyProviderUnavailableError,
        "AWS KMS active KeyRegistry validation unavailable"
    end
  end
end
