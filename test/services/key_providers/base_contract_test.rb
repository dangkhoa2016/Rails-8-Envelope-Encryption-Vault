require_relative "../../crypto_test_helper"

class BaseKeyProviderContractTest < Minitest::Test
  def setup
    @provider = KeyProviders::Base.new
  end

  def test_base_declares_required_provider_operations
    assert_raises(NotImplementedError) { @provider.provider_name }
    assert_raises(NotImplementedError) { @provider.active_key_id }
    assert_raises(NotImplementedError) { @provider.verify_key! }
    assert_raises(NotImplementedError) { @provider.wrap_key(dek: "x" * 32, context: {}) }
    assert_raises(NotImplementedError) do
      @provider.unwrap_key(wrapped_key: "wrapped", key_id: "key", context: {})
    end
  end
end
