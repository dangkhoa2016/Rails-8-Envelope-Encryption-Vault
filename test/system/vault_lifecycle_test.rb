require "application_system_test_case"

class VaultLifecycleTest < ApplicationSystemTestCase
  test "login create edit reveal restore archive and unarchive a vault item" do
    user = create_system_user("vault-flow@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit vault_items_path
    assert_text "No secrets yet"
    assert_link "Create your first secret", href: new_vault_item_path
    click_link "Create your first secret"
    fill_in "Title", with: "Primary account"
    fill_in "Username", with: "alice@example.test"
    fill_in "Secret / password", with: "first-fake-secret"
    fill_in "Url", with: "https://example.test"
    fill_in "Notes", with: "version one"
    click_button "Encrypt and save"

    assert_text "Encrypted secret created."
    item = user.vault_items.order(:created_at).last
    assert_equal 1, item.versions.count

    visit vault_items_path
    expected_login_icon = VaultItemsHelper::KIND_ICONS.fetch("login")
    assert_selector "a[href='#{vault_item_path(item)}'] svg path[d='#{expected_login_icon}']", count: 1

    fill_in "Search encrypted titles", with: "Primary account"
    click_button "Search"
    assert_text "Primary account"
    click_button "Add to favorites"
    assert_text "Added to favorites."
    assert item.reload.favorite?
    check "Favorites"
    click_button "Search"
    assert_text "Primary account"
    refute_includes page.current_url, "Primary+account"
    refute_includes page.current_url, "Primary%20account"
    click_link "Primary account"

    click_link "Edit"
    assert_selector 'section[aria-labelledby="vault-item-secret-heading"] > .space-y-4', count: 1
    secret_row_gaps = page.evaluate_script(<<~JS)
      (() => {
        const group = document.querySelector('section[aria-labelledby="vault-item-secret-heading"] > .space-y-4')
        const rows = Array.from(group.children).filter((el) => getComputedStyle(el).display !== "none")
        return rows.slice(1).map((row, index) => {
          const previous = rows[index].getBoundingClientRect()
          const current = row.getBoundingClientRect()
          return current.top - previous.bottom
        })
      })()
    JS
    assert secret_row_gaps.all? { |gap| gap >= 12 }, "protected-detail rows should retain visible vertical spacing"

    fill_in "Title", with: "Primary account updated"
    fill_in "Notes", with: "version two"
    click_button "Encrypt new version"

    assert_text "New encrypted version created."
    assert_equal 2, item.reload.versions.count

    click_link "Versions"
    assert_text "Version history"
    assert_selector "[data-version-status='current']", text: "Current", count: 1
    accept_confirm { click_button "Restore", match: :first }
    assert_text "Version restored as a new encrypted version."
    assert_equal 3, item.reload.versions.count

    item.current_version.update_column(:created_at, 1.minute.ago)
    Current.reset
    session_record = user.sessions.active.order(:created_at).last
    session_record.update_column(:reauthenticated_at, 1.hour.ago)

    visit vault_item_path(item)
    assert_text "Current version"
    assert_text "v3"
    click_button "Reveal"
    assert_text "Recent identity confirmation is required"
    click_link "Confirm identity"
    fill_in "password", with: TEST_PASSWORD
    click_button "Continue"
    click_button "Reveal"
    assert_text "first-fake-secret"

    accept_confirm("Move this item to Archived? Encrypted data and versions are retained; external credentials are not revoked.") { click_button "Archive" }
    assert_current_path vault_items_path
    assert_no_selector "[data-vault-status='archived']"
    assert item.reload.archived_at.present?
    assert AuditEvent.exists?(user: user, vault_item: item, action: "vault_item.archived")

    visit vault_items_path(status: "archived")
    assert_selector "[data-vault-status='archived']", text: "Archived"
    visit vault_item_path(item)
    assert_selector "[data-vault-status='archived']", text: "Archived"
    click_button "Unarchive"
    assert_current_path vault_items_path
    assert item.reload.archived_at.nil?
    assert AuditEvent.exists?(user: user, vault_item: item, action: "vault_item.unarchived")

    click_link "Audit"
    assert_text "Audit log"
    select "Vault item archived", from: "Action"
    click_button "Filter"
    assert_selector "[data-audit-action='vault_item.archived']", count: 1
    assert_text "Vault item archived"
    assert_no_selector "[data-audit-action='vault_item.unarchived']"
  end
end
