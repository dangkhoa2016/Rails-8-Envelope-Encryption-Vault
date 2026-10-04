require "application_system_test_case"

class MfaEnrollmentTest < ApplicationSystemTestCase
  test "user can enroll MFA, receive recovery codes, and disable MFA" do
    user = create_system_user("mfa-enrollment@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    click_link "MFA"
    assert_text "MFA is not enabled."
    click_link "Set up MFA"
    assert_text "Set up TOTP MFA"

    secret = find("[data-secret-value]", match: :first).text.strip
    token = Security::Totp.code(secret: secret, at: Time.current)
    fill_in "token", with: token
    click_button "Enable MFA"

    assert_text "Save recovery codes now"
    recovery_code = find("pre").text.lines.first.to_s.strip
    assert recovery_code.present?
    assert user.reload.mfa_enabled?
    assert_equal Mfa::RecoveryCodes::COUNT, user.mfa_recovery_codes.count

    click_link "Done"
    assert_text "MFA is enabled."
    disable_form = find_button("Disable MFA").find(:xpath, "./ancestor::form")
    within(disable_form) do
      fill_in "token", with: recovery_code
      accept_confirm("Disable MFA and remove all recovery codes?") { click_button "Disable MFA" }
    end

    assert_text "MFA disabled."
    refute user.reload.mfa_enabled?
    assert_equal 0, user.mfa_recovery_codes.count
  end
end
