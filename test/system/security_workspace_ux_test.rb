require "application_system_test_case"

class SecurityWorkspaceUxTest < ApplicationSystemTestCase
  test "dashboard summarizes security posture and links to security workspaces" do
    user = create_system_user("security-workspace@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    assert_text "Security posture"
    assert_text "Multi-factor authentication"
    assert_link "Not enabled", href: settings_mfa_path
    assert_link "1 session", href: settings_sessions_path
    assert_link "Security settings", href: settings_security_path

    click_link "Security settings", match: :first
    assert_current_path settings_security_path
    assert_selector "nav[aria-label='Security settings'] a[aria-current='page']", text: "Password", count: 1
    assert_link "MFA", href: settings_mfa_path
    assert_link "Sessions", href: settings_sessions_path
  end

  test "security sub-navigation keeps current section visible" do
    user = create_system_user("security-nav@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit settings_mfa_path
    assert_selector "nav[aria-label='Security settings'] a[aria-current='page']", text: "MFA", count: 1
    assert_text "MFA is not enabled."

    visit settings_sessions_path
    assert_selector "nav[aria-label='Security settings'] a[aria-current='page']", text: "Sessions", count: 1
    assert_text "Current session"

    visit audit_events_path
    assert_text "Audit log"
    assert_selector "time[datetime]", minimum: 1
  end
end
