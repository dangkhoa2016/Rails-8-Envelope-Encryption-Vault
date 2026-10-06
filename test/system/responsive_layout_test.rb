require "application_system_test_case"

class ResponsiveLayoutTest < ApplicationSystemTestCase
  test "desktop uses sidebar grid and mobile navigation starts collapsed" do
    user = create_system_user("responsive-layout@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    page.current_window.resize_to(1440, 1000)
    visit root_path
    desktop = page.evaluate_script(<<~JS)
      (() => {
        const wrapper = document.querySelector("[data-controller~='mobile-nav']")
        const nav = document.querySelector("nav[aria-label='Primary navigation']")
        return {
          wrapperDisplay: getComputedStyle(wrapper).display,
          columns: getComputedStyle(wrapper).gridTemplateColumns,
          navDisplay: getComputedStyle(nav).display
        }
      })()
    JS
    assert_equal "grid", desktop["wrapperDisplay"]
    assert_match(/^260px /, desktop["columns"])
    assert_equal "block", desktop["navDisplay"]

    page.current_window.resize_to(390, 844)
    visit root_path
    assert_equal "none", page.evaluate_script(
      "getComputedStyle(document.querySelector(\"nav[aria-label='Primary navigation']\")).display"
    )
    find("button[aria-label='Toggle navigation']").click
    refute_equal "none", page.evaluate_script(
      "getComputedStyle(document.querySelector(\"nav[aria-label='Primary navigation']\")).display"
    )
  end
end
