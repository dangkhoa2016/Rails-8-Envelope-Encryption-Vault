require "test_helper"

class SettingsSessionsPaginationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "sessions-paging@example.test",
      password: "long-password-1234", password_confirmation: "long-password-1234"
    )
    post session_path, params: { email_address: @user.email_address, password: "long-password-1234" }
    assert_redirected_to root_path
    @current = @user.sessions.order(:created_at).last
    22.times do |index|
      @user.sessions.create!(
        user_agent: "ExampleTestSession/#{index + 1}",
        ip_address: "198.51.100.#{index + 10}",
        last_seen_at: Time.current,
        absolute_expires_at: Time.current + 1.day,
        created_at: Time.current - (index + 1).minutes
      )
    end
  end

  test "session history paginates by GET in newest-first stable order with scoped count" do
    other = User.create!(
      email_address: "sessions-paging-other@example.test",
      password: "long-password-1234", password_confirmation: "long-password-1234"
    )
    7.times { other.sessions.create!(user_agent: "OtherUsersDevice", ip_address: "203.0.113.100", last_seen_at: Time.current, absolute_expires_at: Time.current + 1.day) }

    get settings_sessions_path
    assert_response :success
    assert_select "[data-session-count]", text: /23 sessions in account history/
    assert_select "[data-session-id]", 10
    assert_select "[data-session-id='#{@current.id}']", 1
    assert_select "nav[aria-label='Sessions pagination']", 1
    assert_select "nav[aria-label='Sessions pagination'] a[rel='next'][href*='page=2']", 1
    assert_select "nav[aria-label='Sessions pagination'] [aria-current='page']", text: "1"

    get settings_sessions_path(page: 2)
    assert_response :success
    assert_select "[data-session-count]", text: /Showing 11–20/
    assert_select "[data-session-id]", 10
    assert_select "[data-session-id='#{@current.id}']", false
    assert_select "nav[aria-label='Sessions pagination'] a[rel='prev'][href*='page=1']", 1

    get settings_sessions_path(page: 3)
    assert_response :success
    assert_select "[data-session-count]", text: /Showing 21–23/
    assert_select "[data-session-id]", 3
    assert_select "nav[aria-label='Sessions pagination'] a[rel='next']", false
    assert_select "nav[aria-label='Sessions pagination'] [aria-current='page']", text: "3"
    assert_not_includes response.body, "OtherUsersDevice"
  end

  test "invalid page normalizes safely and out-of-range page uses final page" do
    [ "invalid", "-1", "0", "99999999999999999999" ].each do |page|
      get settings_sessions_path(page: page)
      assert_response :success
      assert_select "[data-session-count]", text: /Showing 1–10/
      assert_select "[data-session-id]", 10
    end
    get settings_sessions_path(page: 500)
    assert_response :success
    assert_select "[data-session-count]", text: /Showing 21–23/
    assert_select "nav[aria-label='Sessions pagination'] [aria-current='page']", text: "3"
  end

  test "revoke another session from page three preserves page and revoked status" do
    target = @user.sessions.order(created_at: :asc).first
    delete settings_session_path(target), params: { page: 3 }
    assert_redirected_to settings_sessions_path(page: 3)
    follow_redirect!
    assert_response :success
    assert_select "nav[aria-label='Sessions pagination'] [aria-current='page']", text: "3"
    assert_select "[data-session-id='#{target.id}'] [data-session-status='revoked']", 1
    assert target.reload.revoked_at.present?
    assert @current.reload.revoked_at.nil?
  end

  test "destroy only accesses sessions owned by the authenticated account" do
    other = User.create!(
      email_address: "sessions-revoke-other@example.test",
      password: "long-password-1234", password_confirmation: "long-password-1234"
    )
    foreign = other.sessions.create!(user_agent: "ForeignDevice", last_seen_at: Time.current, absolute_expires_at: Time.current + 1.day)
    delete settings_session_path(foreign), params: { page: 2 }
    assert_response :not_found
    assert_nil foreign.reload.revoked_at
  end
end
