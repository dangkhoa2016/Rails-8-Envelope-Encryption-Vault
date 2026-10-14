require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "idle sessions expire server side" do
    user = User.create!(email_address: "session@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    record = user.sessions.create!(last_seen_at: 2.hours.ago, absolute_expires_at: 1.day.from_now)
    assert record.expired?
  end

  test "revoked sessions are inactive" do
    user = User.create!(email_address: "revoked@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    record = user.sessions.create!(last_seen_at: Time.current, absolute_expires_at: 1.day.from_now, revoked_at: Time.current)
    refute record.active?
  end
end
