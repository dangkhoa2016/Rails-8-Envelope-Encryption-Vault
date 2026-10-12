ENV["DEMO_MODE"] = "true"

require_relative "../test/application_system_test_case"
require "fileutils"

class ShowcaseCaptureTest < ApplicationSystemTestCase
  SHOWCASE_PASSWORD = "showcase-demo-password-1234"

  setup do
    Capybara.save_path = ENV.fetch("SHOWCASE_OUTPUT", Rails.root.join("tmp/showcase/screenshots").to_s)
    FileUtils.mkdir_p(Capybara.save_path)

    @result = Demo::FixtureBuilder.call(password: SHOWCASE_PASSWORD, reset: true)
    visit new_session_path
    fill_in "email_address", with: @result.user.email_address
    fill_in "password", with: SHOWCASE_PASSWORD
    click_button "Sign in"
    assert_text "Your encrypted vault"
  end

  test "capture sanitized portfolio screens" do
    capture("01-dashboard-desktop")

    visit vault_items_path
    assert_text "Acme Analytics"
    capture("02-vault-desktop")

    click_link "Acme Analytics"
    assert_text "Protected contents"
    capture("03-item-detail-desktop")

    click_link "Versions"
    assert_text "Version history"
    capture("04-version-history-desktop")

    visit new_vault_item_path(kind: "login")
    click_button "Generator options"
    assert_text "Balanced · 24"
    capture("05-generator-desktop")

    visit audit_events_path
    assert_text "Audit log"
    capture("06-audit-desktop")

    visit settings_sessions_path
    assert_text "This device"
    capture("07-sessions-desktop")

    visit settings_security_path
    assert_text "Security"
    capture("08-security-desktop")

    page.current_window.resize_to(390, 844)
    visit root_path
    capture("09-dashboard-mobile")

    visit vault_items_path
    capture("10-vault-mobile")
  end

  private

  def capture(name)
    page.save_screenshot(File.join(Capybara.save_path, "#{name}.png"))
  end
end
