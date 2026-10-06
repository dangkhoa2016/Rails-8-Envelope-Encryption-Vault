require "application_system_test_case"

class AccessibilityNavigationTest < ApplicationSystemTestCase
  test "authenticated shell exposes keyboard landmarks and navigation state" do
    user = create_system_user("accessibility@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    skip_link = find("a[href='#main-content']", visible: :all)
    assert_equal "Skip to content", skip_link.text(:all)
    assert_selector "main#main-content[tabindex='-1']", count: 1
    assert_selector "nav[aria-label='Primary navigation'] a[aria-current='page']", text: "Dashboard", count: 1

    page.current_window.resize_to(390, 844)
    visit root_path

    toggle = find("button[aria-label='Toggle navigation']")
    assert_equal "primary-navigation", toggle["aria-controls"]
    assert_equal "false", toggle["aria-expanded"]

    toggle.click
    assert_equal "true", toggle["aria-expanded"]

    toggle.click
    assert_equal "false", toggle["aria-expanded"]
  end
end
