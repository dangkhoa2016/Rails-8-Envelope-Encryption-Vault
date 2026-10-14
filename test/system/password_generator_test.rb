require "application_system_test_case"

class PasswordGeneratorTest < ApplicationSystemTestCase
  test "generator supports presets configurable groups copy and search-space guidance" do
    user = create_system_user("generator@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit new_vault_item_path(kind: "login")
    click_button "Generator options"

    assert_selector "#secret-generator-options:not(.hidden)"
    assert_text "Estimated search space:"

    click_button "Strong · 32"
    input = find("input[name='secret_value']", visible: :all)
    strong_value = input.value
    assert_equal 32, strong_value.length
    assert_text "Generated 32-character secret"

    page.execute_script(<<~JS)
      window.__copiedSecret = null
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: { writeText: async (text) => { window.__copiedSecret = text } }
      })
    JS
    click_button "Copy"
    assert_equal strong_value, page.evaluate_script("window.__copiedSecret")
    assert_text "Copied"

    find("#secret-generator-length").set(32)
    uncheck "Symbols"
    click_button "Generate secure secret"

    value = input.value
    assert_equal 32, value.length
    assert_match(/[A-Z]/, value)
    assert_match(/[a-z]/, value)
    assert_match(/[2-9]/, value)
    assert value.each_char.none? { |character| "!@#$%^&*_-+=".include?(character) }
    assert_no_match(/[Il1O0o]/, value)
    assert_text "This is an estimate, not a guarantee of security."
  end
end
