require_relative "../crypto/unknown_key_provider_error"
require_relative "../crypto/key_provider_configuration_error"

require_relative "base"
require_relative "local_file"
require_relative "aws_kms_client"
require_relative "aws_kms_active_key_guard"
require_relative "external_kms"

module KeyProviders
  class Registry
    def self.fetch(name = configured_name)
      case name.to_s
      when "local_file"
        LocalFile.new(
          key_dir: configured_key_dir,
          active_key_id: configured_active_key_id
        )
      when "aws_kms"
        region = configured_aws_region.to_s
        key_id = configured_active_key_id.to_s

        raise Crypto::KeyProviderConfigurationError, "AWS KMS region is required" if region.empty?
        raise Crypto::KeyProviderConfigurationError, "AWS KMS active key id is required" if key_id.empty?

        ExternalKms.new(
          provider_name: "aws_kms",
          active_key_id: key_id,
          client: AwsKmsClient.new(region: region),
          write_guard: AwsKmsActiveKeyGuard.method(:verify!)
        )
      else
        raise Crypto::UnknownKeyProviderError, "unknown key provider: #{name}"
      end
    end

    def self.configured_name
      defined?(Rails) ? Rails.configuration.x.vault.key_provider : ENV.fetch("VAULT_KEY_PROVIDER", "local_file")
    end

    def self.configured_key_dir
      defined?(Rails) ? Rails.configuration.x.vault.kek_dir : ENV.fetch("VAULT_KEK_DIR", ".local/keks")
    end

    def self.configured_active_key_id
      defined?(Rails) ? Rails.configuration.x.vault.active_kek_id : ENV.fetch("VAULT_ACTIVE_KEK_ID", "kek-dev-01")
    end

    def self.configured_aws_region
      if defined?(Rails)
        Rails.configuration.x.vault.aws_region
      else
        ENV["AWS_REGION"].presence || ENV["AWS_DEFAULT_REGION"]
      end
    end
  end
end
