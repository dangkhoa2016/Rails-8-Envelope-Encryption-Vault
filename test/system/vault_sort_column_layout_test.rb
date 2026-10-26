require "application_system_test_case"

class VaultSortColumnLayoutTest < ApplicationSystemTestCase
  test "Favorite header and direction icon stay inside the table and align with star on desktop" do
    user = create_system_user("sort-column-layout@example.test")
    sign_in_system_user(user)

    Vault::CreateItem.call(user:, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Favorite layout sample",
      "username" => "demo@example.test", "password" => "fake-demo-only",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })

    [ 1400, 1280, 900 ].each do |width|
      page.current_window.resize_to(width, 1000)
      visit vault_items_path
      assert_selector '[role="columnheader"][aria-sort="descending"] a[href*="sort=favorite"]'

      geometry = evaluate_script(<<~JS)
        (() => {
          const header = document.querySelector('[role="columnheader"] a[href*="sort=favorite"]');
          const table = header.closest('.overflow-hidden');
          const favorite = document.querySelector('[id^="listing_favorite_control_vault_item_"] button');
          const linkRect = header.getBoundingClientRect();
          const tableRect = table.getBoundingClientRect();
          const favoriteRect = favorite.getBoundingClientRect();
          return {
            linkWidth: linkRect.width,
            tableRight: tableRect.right,
            labelRight: linkRect.right,
            favoriteRight: favoriteRect.right,
            labelLeft: linkRect.left,
            tableLeft: tableRect.left,
            scrollWidth: header.scrollWidth,
            clientWidth: header.clientWidth
          };
        })()
      JS

      assert_operator geometry.fetch("linkWidth"), :>, 75, "Favorite header should fit label + arrow at #{width}px"
      assert_operator geometry.fetch("labelRight"), :<=, geometry.fetch("tableRight") - 1,
        "Favorite header clips outside table at #{width}px"
      assert_operator geometry.fetch("labelLeft"), :>=, geometry.fetch("tableLeft") + 1,
        "Favorite header clips at left at #{width}px"
      assert_operator geometry.fetch("scrollWidth"), :<=, geometry.fetch("clientWidth") + 1,
        "Favorite sort arrow is clipped at #{width}px"
      assert_in_delta geometry.fetch("labelRight"), geometry.fetch("favoriteRight"), 3,
        "Favorite header should right-align with star button at #{width}px"
    end

    page.current_window.resize_to(550, 950)
    visit vault_items_path
    assert_selector "[data-vault-sort-status]", text: "Favorite ↓ Descending"
    assert_no_selector '[role="columnheader"] a[href*="sort=favorite"]', visible: true
    assert_selector 'a[aria-label="Sort by Favorite ascending"]', visible: true
  end
end
