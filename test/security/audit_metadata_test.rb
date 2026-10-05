require "test_helper"

class AuditMetadataTest < ActiveSupport::TestCase
  test "rejects sensitive metadata keys" do
    event = AuditEvent.new(action: "test", metadata: { "password" => "do-not-log" })
    refute event.valid?
    assert_includes event.errors[:metadata].join(" "), "forbidden"
  end

  test "allows operational metadata" do
    event = AuditEvent.new(action: "key.rotation_completed", metadata: { "from" => "kek-a", "to" => "kek-b", "verified" => 4 })
    assert event.valid?
  end
end
