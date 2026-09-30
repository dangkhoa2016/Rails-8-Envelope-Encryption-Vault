module KeyProviders
  class AwsKmsClient
    def initialize(region:, sdk_client: nil)
      @region = region.to_s
      raise ArgumentError, "AWS KMS region is required" if @region.empty?

      @sdk_client = sdk_client || build_sdk_client
    end

    def key_available?(key_id:)
      response = @sdk_client.describe_key(key_id: key_id.to_s)
      metadata = response.key_metadata

      metadata.enabled &&
        metadata.key_usage == "ENCRYPT_DECRYPT"
    rescue StandardError => error
      return false if error.class.name == "Aws::KMS::Errors::NotFoundException"

      raise
    end

    def encrypt(key_id:, plaintext:, encryption_context:)
      response = @sdk_client.encrypt(
        key_id: key_id.to_s,
        plaintext: String(plaintext).b,
        encryption_context: stringify_context(encryption_context)
      )

      String(response.ciphertext_blob).b
    end
    def decrypt(key_id:, ciphertext:, encryption_context:)
      response = @sdk_client.decrypt(
        key_id: key_id.to_s,
        ciphertext_blob: String(ciphertext).b,
        encryption_context: stringify_context(encryption_context)
      )

      String(response.plaintext).b
    end

    private

    def build_sdk_client
      require "aws-sdk-kms"
      Aws::KMS::Client.new(region: @region)
    end

    def stringify_context(context)
      context.to_h.transform_keys(&:to_s).transform_values(&:to_s)
    end
  end
end
