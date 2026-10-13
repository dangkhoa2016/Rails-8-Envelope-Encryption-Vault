require_relative "../../crypto_test_helper"

class AadBuilderTest < Minitest::Test
  def test_aad_is_deterministic_and_bound_to_ids
    args = { envelope_version: 1, aad_version: 1, user_id: "u-1", vault_item_id: "i-1", vault_item_version_id: "v-1" }
    a = Crypto::AadBuilder.call(**args)
    b = Crypto::AadBuilder.call(**args)
    assert_equal a, b
    refute_equal a, Crypto::AadBuilder.call(**args.merge(user_id: "u-2"))
  end

  def test_rejects_delimiter_in_identifier
    assert_raises(ArgumentError) do
      Crypto::AadBuilder.call(envelope_version: 1, aad_version: 1, user_id: "bad|id", vault_item_id: "i", vault_item_version_id: "v")
    end
  end
end
