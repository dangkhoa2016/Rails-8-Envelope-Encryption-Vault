module KeyProviders
  class Diagnostics
    Result = Data.define(:provider_name, :status, :category, :remote) do
      def ready? = status == "ready"
    end

    SAFE_PROVIDER_NAMES = %w[local_file aws_kms].freeze

    def self.call(provider_name: Registry.configured_name, provider: nil)
      safe_name = safe_provider_name(provider_name)
      provider ||= Registry.fetch(provider_name)
      provider.verify_key!
      provider.assert_write_allowed! if provider.respond_to?(:assert_write_allowed!)

      Result.new(
        provider_name: safe_name,
        status: "ready",
        category: "none",
        remote: remote_provider?(provider, safe_name)
      )
    rescue Crypto::KeyProviderConfigurationError, Crypto::UnknownKeyProviderError
      Result.new(provider_name: safe_name, status: "misconfigured", category: "configuration", remote: safe_name == "aws_kms")
    rescue Crypto::KeyProviderUnavailableError, Crypto::UnknownKeyError
      Result.new(provider_name: safe_name, status: "unavailable", category: "availability", remote: safe_name == "aws_kms")
    rescue Crypto::Error
      Result.new(provider_name: safe_name, status: "error", category: "crypto", remote: safe_name == "aws_kms")
    rescue StandardError
      Result.new(provider_name: safe_name, status: "unavailable", category: "availability", remote: safe_name == "aws_kms")
    end

    def self.safe_provider_name(name)
      value = name.to_s
      SAFE_PROVIDER_NAMES.include?(value) ? value : "unknown"
    end
    private_class_method :safe_provider_name

    def self.remote_provider?(provider, safe_name)
      return true if safe_name == "aws_kms"
      return false unless provider.respond_to?(:capabilities)

      provider.capabilities[:remote_kek] == true
    end
    private_class_method :remote_provider?
  end
end
