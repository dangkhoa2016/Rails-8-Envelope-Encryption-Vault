require "application_system_test_case"

class SettingsSessionsPaginationTest < ApplicationSystemTestCase
  test "session list navigates with GET and revoking a prior session preserves the current page" do
    user = create_system_user("sessions-pagy-browser@example.test")
    sign_in_system_user(user)
    current_id = user.sessions.order(:created_at).last.id
    records = 23.times.map do |index|
      user.sessions.create!(
        user_agent: "SyntheticBrowser/#{index + 1}",
        ip_address: "198.51.100.#{index + 10}",
        created_at: Time.current - (index + 1).minutes,
        last_seen_at: Time.current,
        absolute_expires_at: Time.current + 1.day
      )
    end

    visit settings_sessions_path
    assert_text "24 sessions in account history"
    assert_text "Page 1 of 3"
    assert_selector "[data-session-id]", count: 10
    assert_selector "[data-session-id='#{current_id}']", count: 1
    assert_selector "nav[aria-label='Sessions pagination'] a[rel='next']", count: 1

    click_link "Next", match: :first
    assert_text "Page 2 of 3"
    assert_current_path settings_sessions_path(page: 2)
    assert_selector "[data-session-id]", count: 10
    assert_no_selector "[data-session-id='#{current_id}']"
    assert_text "Showing 11–20"

    record = records[10] # This older session is on page 2.
    within("[data-session-id='#{record.id}']") do
      accept_confirm("Revoke this session?") { click_button "Revoke" }
    end
    assert_current_path settings_sessions_path(page: 2)
    assert_selector "[data-session-id='#{record.id}'] [data-session-status='revoked']", text: "Revoked"
    assert_text "Page 2 of 3"
    assert user.sessions.find(record.id).revoked_at.present?

    click_link "Next", match: :first
    assert_current_path settings_sessions_path(page: 3)
    assert_text "Page 3 of 3"
    assert_selector "[data-session-id]", count: 4
    click_link "Previous"
    assert_current_path settings_sessions_path(page: 2)
    assert_text "Page 2 of 3"
  end

  test "session pagination remains usable on mobile and single page needs no pagination" do
    user = create_system_user("sessions-mobile-pagy@example.test")
    sign_in_system_user(user)
    visit settings_sessions_path
    assert_text "1 session in account history"
    assert_no_selector "nav[aria-label='Sessions pagination']"

    13.times do |index|
      user.sessions.create!(
        user_agent: "SyntheticMobileBrowser/#{index + 1}",
        ip_address: "198.51.100.#{index + 10}",
        created_at: Time.current - (index + 1).minutes,
        last_seen_at: Time.current,
        absolute_expires_at: Time.current + 1.day
      )
    end
    page.current_window.resize_to(390, 850)
    visit settings_sessions_path
    assert_text "Page 1 of 2"
    assert_selector "nav[aria-label='Sessions pagination'] a[rel='next']", visible: true
    assert_operator evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth"),
      :<=, 1, "Sessions should not overflow horizontally on a narrow phone"
    click_link "Next"
    assert_text "Page 2 of 2"
    assert_selector "[data-session-id]", count: 4
  end
end
