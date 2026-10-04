require "test_helper"

class SessionSecurityTest < ActionDispatch::IntegrationTest
  test "login cookie is not a permanent multi-year cookie" do
    user = User.create!(email_address: "cookie@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    assert_response :redirect
    assert user.sessions.last.absolute_expires_at <= Rails.configuration.x.security.session_absolute_timeout.from_now + 5.seconds
  end
end
