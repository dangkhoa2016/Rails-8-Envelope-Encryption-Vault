require "test_helper"

class TotpTest < ActiveSupport::TestCase
  RFC_SECRET = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
  RFC_VECTORS = {
    59 => "94287082",
    1_111_111_109 => "07081804",
    1_111_111_111 => "14050471",
    1_234_567_890 => "89005924",
    2_000_000_000 => "69279037",
    20_000_000_000 => "65353130"
  }.freeze

  test "matches RFC 6238 SHA1 vectors" do
    RFC_VECTORS.each do |timestamp, expected|
      assert_equal expected, Security::Totp.code(secret: RFC_SECRET, at: Time.at(timestamp), digits: 8)
    end
  end
end
