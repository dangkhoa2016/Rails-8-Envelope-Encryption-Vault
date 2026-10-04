require "application_system_test_case"

class MfaAndSessionsTest < ApplicationSystemTestCase
  test "MFA login accepts TOTP and a one time recovery code" do
    user = create_system_user("mfa-system@example.test")
    secret = Security::Totp.generate_secret
    Mfa::SecretStore.enable!(user: user, secret: secret)
    recovery_code = Mfa::RecoveryCodes.regenerate!(user: user).first

    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: TEST_PASSWORD
    click_button "Sign in"
    assert_text "Two-factor authentication"

    fill_in "token", with: Security::Totp.code(secret: secret, at: Time.current)
    click_button "Verify"
    assert_text "Your encrypted vault"

    click_button "Sign out"
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: TEST_PASSWORD
    click_button "Sign in"
    fill_in "token", with: recovery_code
    click_button "Verify"
    assert_text "Your encrypted vault"

    assert_equal 1, user.mfa_recovery_codes.reload.where.not(used_at: nil).count
  end

  test "user can revoke the current browser session" do
    user = create_system_user("session-system@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    click_link "Sessions"
    assert_text "Sessions"
    assert_text "Chrome on Linux"
    assert_text "Desktop"
    assert_text "This device"
    assert_selector "[data-session-status='current']", text: "Current session", count: 1
    accept_confirm("Revoke this current session and sign out?") { click_button "Revoke current session" }

    assert_current_path new_session_path
    assert_text "Session revoked."
    assert_text "Sign in"
    assert user.sessions.reload.where.not(revoked_at: nil).exists?
  end
end
