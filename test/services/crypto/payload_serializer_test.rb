require_relative "../../crypto_test_helper"

class PayloadSerializerTest < Minitest::Test
  def test_unicode_round_trip
    payload = { "title" => "Mật khẩu", "note" => "xin chào 🔐" }
    assert_equal payload, Crypto::PayloadSerializer.load(Crypto::PayloadSerializer.dump(payload))
  end

  def test_rejects_invalid_utf8
    assert_raises(ArgumentError) { Crypto::PayloadSerializer.load("\xFF".b) }
  end
end
