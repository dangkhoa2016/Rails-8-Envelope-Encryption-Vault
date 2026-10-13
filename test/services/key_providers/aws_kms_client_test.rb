require_relative "../../crypto_test_helper"
require_relative "../../../app/services/key_providers/aws_kms_client"

unless defined?(Aws::KMS::Errors::NotFoundException)
  module Aws
    module KMS
      module Errors
        class NotFoundException < StandardError; end
      end
    end
  end
end

class AwsKmsClientTest < Minitest::Test
  Response = Struct.new(:key_metadata, :ciphertext_blob, :plaintext, keyword_init: true)
  KeyMetadata = Struct.new(:enabled, :key_usage, keyword_init: true)

  class FakeSdk
    attr_reader :encrypt_params, :decrypt_params

    def describe_key(key_id:)
      if key_id == "missing"
        klass = Aws::KMS::Errors::NotFoundException
        error = begin
          klass.new(nil, "missing")
        rescue ArgumentError
          klass.new("missing")
        end
        raise error
      end

      Response.new(
        key_metadata: KeyMetadata.new(enabled: true, key_usage: "ENCRYPT_DECRYPT")
      )
    end

    def encrypt(**params)
      @encrypt_params = params
      Response.new(ciphertext_blob: "ciphertext".b)
    end

    def decrypt(**params)
      @decrypt_params = params
      Response.new(plaintext: "p" * 32)
    end
  end

  def setup
    @sdk = FakeSdk.new
    @client = KeyProviders::AwsKmsClient.new(region: "ap-southeast-1", sdk_client: @sdk)
    @context = { user_id: 7, purpose: :test }
  end

  def test_key_availability
    assert @client.key_available?(key_id: "arn:aws:kms:example")
    refute @client.key_available?(key_id: "missing")
  end

  def test_encrypt_forwards_binary_plaintext_and_string_context
    result = @client.encrypt(
      key_id: "key-1",
      plaintext: ("x" * 32).b,
      encryption_context: @context
    )

    assert_equal "ciphertext".b, result
    assert_equal "key-1", @sdk.encrypt_params[:key_id]
    assert_equal({ "user_id" => "7", "purpose" => "test" },
                 @sdk.encrypt_params[:encryption_context])
  end

  def test_decrypt_forwards_ciphertext_and_context
    result = @client.decrypt(
      key_id: "key-1",
      ciphertext: "ciphertext".b,
      encryption_context: @context
    )
    assert_equal "p" * 32, result
    assert_equal "key-1", @sdk.decrypt_params[:key_id]
    assert_equal "ciphertext".b, @sdk.decrypt_params[:ciphertext_blob]
    assert_equal({ "user_id" => "7", "purpose" => "test" },
                 @sdk.decrypt_params[:encryption_context])
  end

  def test_non_not_found_describe_error_is_not_hidden
    sdk = Object.new
    def sdk.describe_key(key_id:) = raise("credential failure")

    client = KeyProviders::AwsKmsClient.new(region: "ap-southeast-1", sdk_client: sdk)
    error = assert_raises(RuntimeError) { client.key_available?(key_id: "key-1") }
    assert_equal "credential failure", error.message
  end

  def test_region_is_required
    assert_raises(ArgumentError) do
      KeyProviders::AwsKmsClient.new(region: "", sdk_client: @sdk)
    end
  end
end
