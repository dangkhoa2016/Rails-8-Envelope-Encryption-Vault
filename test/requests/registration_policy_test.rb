require "test_helper"

class RegistrationPolicyTest < ActionDispatch::IntegrationTest
  test "registration is closed by default" do
    old = ENV["ALLOW_SIGNUPS"]
    ENV["ALLOW_SIGNUPS"] = "false"
    get new_registration_path
    assert_response :not_found
  ensure
    ENV["ALLOW_SIGNUPS"] = old
  end
end
