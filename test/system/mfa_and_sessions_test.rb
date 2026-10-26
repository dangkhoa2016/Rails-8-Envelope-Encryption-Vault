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
    click_link "Recovery code", exact: true
    assert_selector '[data-mfa-active-method="recovery"]'
    assert_field "Recovery code", with: ""
    assert_equal "text", find_field("token")["inputmode"]
    fill_in "token", with: recovery_code
    click_button "Verify"
    assert_text "Your encrypted vault"

    assert_equal 1, user.mfa_recovery_codes.reload.where.not(used_at: nil).count
  end

  test "MFA method switch uses a Turbo Frame and keeps recovery selection after invalid code" do
    user = create_system_user("mfa-recovery-mode@example.test")
    secret = Security::Totp.generate_secret
    Mfa::SecretStore.enable!(user: user, secret: secret)
    recovery = Mfa::RecoveryCodes.regenerate!(user: user).first

    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: TEST_PASSWORD
    click_button "Sign in"
    assert_current_path new_mfa_challenge_path
    assert_selector '[data-mfa-active-method="authenticator"]'
    assert_field "6-digit authentication code", with: ""
    assert_equal "numeric", find_field("token")["inputmode"]
    assert_equal "6", find_field("token")["maxlength"]
    assert_selector "a[data-mfa-method='authenticator'][aria-current='page']"
    execute_script("window.__mfaChallengeNoReload = true")

    click_link "Recovery code", exact: true
    assert_selector '[data-mfa-active-method="recovery"]'
    assert_field "Recovery code", with: ""
    assert_equal "text", find_field("token")["inputmode"]
    assert_equal "19", find_field("token")["maxlength"]
    assert_equal true, evaluate_script("window.__mfaChallengeNoReload")
    assert_selector "a[data-mfa-method='recovery'][aria-current='page']"
    assert_current_path(/method=recovery/, ignore_query: false)

    fill_in "token", with: "FFFF-FFFF-FFFF-FFFF"
    click_button "Verify"
    assert_selector "#mfa-challenge-error", text: "We couldn't verify that code"
    assert_selector '[data-mfa-active-method="recovery"]'
    assert_field "Recovery code", with: ""
    assert_no_text "FFFF-FFFF-FFFF-FFFF"
    assert_equal 0, user.mfa_recovery_codes.reload.where.not(used_at: nil).count

    fill_in "token", with: recovery
    click_button "Verify"
    assert_current_path root_path
    assert_text "Your encrypted vault"
    assert_equal 1, user.mfa_recovery_codes.reload.where.not(used_at: nil).count
  end

  test "MFA challenge stays readable and prevents horizontal overflow on mobile" do
    user = create_system_user("mfa-mobile-layout@example.test")
    Mfa::SecretStore.enable!(user: user, secret: Security::Totp.generate_secret)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: TEST_PASSWORD
    click_button "Sign in"

    [ 1400, 768, 390 ].each do |width|
      page.current_window.resize_to(width, 900)
      assert_selector "[data-mfa-challenge]"
      assert_selector "a[data-mfa-method='recovery']", visible: true
      assert_button "Verify", visible: true
      overflow = evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
      assert_operator overflow, :<=, 1, "MFA challenge overflows horizontally at #{width}px"
    end
    page.current_window.resize_to(390, 900)
    click_link "Recovery code", exact: true
    assert_selector '[data-mfa-active-method="recovery"]'
    assert_selector "input[name='token'][placeholder='XXXX-XXXX-XXXX-XXXX']"
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
