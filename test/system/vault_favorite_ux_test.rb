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
    assert_favorite_submission_lock("#vault_favorite_control")
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
  test "listing page 4 favorite toggles in place without jumping to page 1" do
    user = create_system_user("favorite-paging-browser@example.test")
    sign_in_system_user(user)
    20.times do |index|
      Vault::CreateItem.call(user:, kind: "login", payload: {
        "schema" => "vault.login.v1", "title" => format("Page four sample %02d", index + 1),
        "username" => "test@example.test", "password" => "synthetic-secret",
        "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
      })
    end

    visit vault_items_path(page: 4)
    assert_text "Page 4 of 4"
    original_url = page.current_url
    control = find("#vault_listing [id^='listing_favorite_control_vault_item_']", match: :first)
    control_id = control[:id]
    assert_favorite_submission_lock("##{control_id}")
    execute_script("window.__listingFavoriteNoReload = true")

    within("##{control_id}") { click_button "Add to favorites" }
    assert_selector "##{control_id} button[aria-label='Remove from favorites']"
    assert_selector "#toast_notifications [role='status']", text: "Added to favorites."
    assert_equal original_url, page.current_url
    assert_text "Page 4 of 4"
    assert_equal true, evaluate_script("window.__listingFavoriteNoReload")
    assert_equal "Remove from favorites", evaluate_script("document.activeElement.getAttribute('aria-label')")

    within("##{control_id}") { click_button "Remove from favorites" }
    assert_selector "##{control_id} button[aria-label='Add to favorites']"
    assert_selector "#toast_notifications [role='status']", text: "Removed from favorites."
    assert_equal original_url, page.current_url
    assert_text "Page 4 of 4"
    assert_equal true, evaluate_script("window.__listingFavoriteNoReload")
    assert_equal "Add to favorites", evaluate_script("document.activeElement.getAttribute('aria-label')")
  end

  private

  def assert_favorite_submission_lock(selector)
    execute_script(<<~JS)
      const form = document.querySelector(#{selector.to_json} + " form");
      form.dispatchEvent(new CustomEvent("turbo:submit-start", { bubbles: true }));
    JS
    assert_selector "#{selector} button[type='submit']:disabled[aria-busy='true']"

    # An unsuccessful response keeps the old control, which must be enabled.
    execute_script(<<~JS)
      const form = document.querySelector(#{selector.to_json} + " form");
      form.dispatchEvent(new CustomEvent("turbo:submit-end", { bubbles: true, detail: { success: false } }));
    JS
    assert_selector "#{selector} button[type='submit']:not(:disabled):not([aria-busy])"
  end
end
