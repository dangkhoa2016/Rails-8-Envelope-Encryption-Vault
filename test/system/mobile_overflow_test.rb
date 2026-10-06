require "application_system_test_case"

class MobileOverflowTest < ApplicationSystemTestCase
  test "key authenticated pages do not overflow horizontally on mobile" do
    user = create_system_user("mobile-overflow@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"
    page.current_window.resize_to(390, 844)

    [
      root_path,
      vault_items_path,
      new_vault_item_path(kind: "database"),
      settings_security_path
    ].each do |path|
      visit path
      widths = page.evaluate_script(<<~JS)
        ({
          client: document.documentElement.clientWidth,
          scroll: document.documentElement.scrollWidth
        })
      JS
      assert_equal widths["client"], widths["scroll"], "horizontal overflow at #{path}"
    end
  end
end
