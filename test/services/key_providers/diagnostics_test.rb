require "test_helper"
require_relative "../../../app/services/key_providers/diagnostics"

class KeyProvidersDiagnosticsTest < ActiveSupport::TestCase
  class ReadyProvider
    def verify_key! = true
    def assert_write_allowed! = true
    def capabilities = { remote_kek: true }
  end

  class FailingProvider
    def initialize(error)
      @error = error
    end

    def verify_key!
      raise @error
    end

    def capabilities = { remote_kek: true }
  end

  test "ready provider exposes only safe readiness metadata" do
    result = KeyProviders::Diagnostics.call(provider_name: "aws_kms", provider: ReadyProvider.new)

    assert_equal "aws_kms", result.provider_name
    assert_equal "ready", result.status
    assert_equal "none", result.category
    assert_equal true, result.remote
    assert result.ready?
  end

  test "write guard mismatch maps to safe configuration status" do
    provider = ReadyProvider.new
    provider.define_singleton_method(:assert_write_allowed!) do
      raise Crypto::KeyProviderConfigurationError, "AWS KMS configured active key does not match KeyRegistry"
    end

    result = KeyProviders::Diagnostics.call(provider_name: "aws_kms", provider: provider)

    assert_equal "aws_kms", result.provider_name
    assert_equal "misconfigured", result.status
    assert_equal "configuration", result.category
    assert_equal true, result.remote
    refute result.ready?

    rendered = [ result.provider_name, result.status, result.category ].join(" ")
    refute_includes rendered, "KeyRegistry"
    refute_includes rendered, "active key"
  end

  test "credential expiry maps to generic availability without leaking detail" do
    error = RuntimeError.new("ExpiredToken: AKIA-SECRET credential expired")
    result = KeyProviders::Diagnostics.call(provider_name: "aws_kms", provider: FailingProvider.new(error))

    assert_equal "aws_kms", result.provider_name
    assert_equal "unavailable", result.status
    assert_equal "availability", result.category
    refute result.ready?

    rendered = [ result.provider_name, result.status, result.category ].join(" ")
    refute_includes rendered, "ExpiredToken"
    refute_includes rendered, "AKIA"
    refute_includes rendered, "credential"
  end

  test "access denied maps to generic availability without leaking provider message" do
    error = Crypto::KeyProviderUnavailableError.new("AccessDenied arn:aws:kms:ap-southeast-1:123456789012:key/private")
    result = KeyProviders::Diagnostics.call(provider_name: "aws_kms", provider: FailingProvider.new(error))

    assert_equal "unavailable", result.status
    assert_equal "availability", result.category
    rendered = [ result.provider_name, result.status, result.category ].join(" ")
    refute_includes rendered, "AccessDenied"
    refute_includes rendered, "arn:aws:kms"
    refute_includes rendered, "123456789012"
  end

  test "unknown provider name is reduced to safe unknown marker" do
    result = KeyProviders::Diagnostics.call(provider_name: "vendor-secret-name", provider: ReadyProvider.new)

    assert_equal "unknown", result.provider_name
    assert_equal "ready", result.status
    assert_equal true, result.remote
  end
end
