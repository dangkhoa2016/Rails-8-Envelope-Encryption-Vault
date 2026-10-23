require "application_system_test_case"

class VaultFavoriteUxTest < ApplicationSystemTestCase
  test "favorite toggles in place without losing detail location or keyboard focus" do
    user = create_system_user("favorite-detail-browser@example.test")
    sign_in_system_user(user)
    item = Vault::CreateItem.call(user: user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Favorite browser smoke",
      "username" => "synthetic@example.test", "password" => "fake-secret",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })

    visit vault_item_path(item)
    assert_selector '#vault_favorite_control button[aria-label="Add to favorites"]'
    execute_script("window.__favoriteNoReload = true")
    click_button "Add to favorites"

    assert_selector '#vault_favorite_control button[aria-label="Remove from favorites"]'
    assert_selector '#toast_notifications [role="status"]', text: "Added to favorites."
    assert_current_path vault_item_path(item)
    assert_no_selector '#vault_favorite_control [role="status"]'
    assert_equal "fixed", evaluate_script("getComputedStyle(document.getElementById('toast_notifications')).position")
    assert_equal true, evaluate_script("window.__favoriteNoReload")
    assert_equal "Remove from favorites", evaluate_script("document.activeElement.getAttribute('aria-label')")
    assert item.reload.favorite?

    click_button "Remove from favorites"
    assert_selector '#vault_favorite_control button[aria-label="Add to favorites"]'
    assert_selector '#toast_notifications [role="status"]', text: "Removed from favorites."
    assert_current_path vault_item_path(item)
    assert_no_selector '#vault_favorite_control [role="status"]'
    assert_equal "fixed", evaluate_script("getComputedStyle(document.getElementById('toast_notifications')).position")
    assert_equal true, evaluate_script("window.__favoriteNoReload")
    assert_equal "Add to favorites", evaluate_script("document.activeElement.getAttribute('aria-label')")
    assert_not item.reload.favorite?

    assert_equal 1, AuditEvent.where(user: user, vault_item: item, action: "vault_item.favorited").count
    assert_equal 1, AuditEvent.where(user: user, vault_item: item, action: "vault_item.unfavorited").count
  end
end
