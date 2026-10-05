require "test_helper"

class EnvParserTest < ActiveSupport::TestCase
  test "parses equals signs and quoted unicode" do
    entries = Vault::EnvParser.parse("A=a=b\nB=\"xin chào\"\n")
    assert_equal [ { "key" => "A", "value" => "a=b" }, { "key" => "B", "value" => "xin chào" } ], entries
  end

  test "rejects duplicate keys" do
    assert_raises(ArgumentError) { Vault::EnvParser.parse("A=1\nA=2") }
  end
end
