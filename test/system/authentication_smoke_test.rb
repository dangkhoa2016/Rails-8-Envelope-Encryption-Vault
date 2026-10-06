require "application_system_test_case"

class AuthenticationSmokeTest < ApplicationSystemTestCase
  test "unauthenticated visitor is redirected to sign in" do
    visit root_path

    assert_current_path new_session_path
    assert_text "Sign in"
  end
end
