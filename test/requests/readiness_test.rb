require "test_helper"

class ReadinessTest < ActionDispatch::IntegrationTest
  test "ready returns ok when the database key provider and write guard are healthy" do
    provider = Object.new
    provider.define_singleton_method(:verify_key!) { true }
    provider.define_singleton_method(:assert_write_allowed!) { true }

    with_registry_provider(provider) { get readiness_check_path }

    assert_response :ok
    assert_empty response.body
  end

  test "ready fails closed when write guard detects active key drift" do
    provider = Object.new
    provider.define_singleton_method(:verify_key!) { true }
    provider.define_singleton_method(:assert_write_allowed!) do
      raise Crypto::KeyProviderConfigurationError, "AWS KMS configured active key does not match KeyRegistry"
    end

    with_registry_provider(provider) { get readiness_check_path }

    assert_response :service_unavailable
    assert_empty response.body
  end

  test "ready fails closed without exposing provider error details" do
    provider = Object.new
    provider.define_singleton_method(:verify_key!) { raise Crypto::Error, "sensitive provider detail" }

    with_registry_provider(provider) { get readiness_check_path }

    assert_response :service_unavailable
    assert_empty response.body
    refute_includes response.body, "sensitive provider detail"
  end

  private

  def with_registry_provider(provider)
    singleton = KeyProviders::Registry.singleton_class
    original = KeyProviders::Registry.method(:fetch)
    singleton.define_method(:fetch) { |*_args| provider }
    yield
  ensure
    singleton.define_method(:fetch, original)
  end
end
