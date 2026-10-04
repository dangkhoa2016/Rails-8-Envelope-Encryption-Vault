require "application_system_test_case"

class VaultCategoryGuidanceTest < ApplicationSystemTestCase
  test "new item chooser explains categories and adapts protected fields" do
    user = create_system_user("category-guidance@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit new_vault_item_path
    assert_text "What do you want to protect?"
    assert_text "Best for:"
    assert_text "Websites, SaaS accounts, admin portals, and personal sign-ins"
    assert_text "TYPICAL FIELDS"
    assert_text "Username · Password · Website URL"
    assert_text "Item identity"
    assert_text "Protected details"
    assert_text "Organization"

    click_link "Secure note"
    assert_current_path new_vault_item_path(kind: "secure_note")
    assert_text "Recovery codes, private instructions, license data, and sensitive notes"
    assert_text "Protected note"
    assert_field "Secure note"
    assert_no_field "Username"
  end

  test "edit page explains fixed type and versioning safety" do
    user = create_system_user("edit-guidance@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit new_vault_item_path(kind: "login")
    fill_in "Title", with: "Guided login"
    fill_in "Username", with: "guide@example.test"
    fill_in "Secret / password", with: "fake-guided-secret"
    fill_in "Url", with: "https://example.test"
    click_button "Encrypt and save"

    assert_text "ABOUT THIS TEMPLATE"
    assert_text "PROTECTED FIELD PATTERN"
    assert_text "Username · Password · Website URL"
    assert_text "Item lifecycle"

    click_link "Edit"
    assert_text "Create a new encrypted version"
    assert_text "Item type is fixed after creation"
    assert_text "VERSIONING SAFETY"
    assert_text "Leave the secret field blank to keep its current encrypted value"
    assert_text "Websites, SaaS accounts, admin portals, and personal sign-ins"
    assert_field "Title", with: "Guided login"
  end

  test "vault filters expose accessible labels and active-filter recovery" do
    user = create_system_user("filter-guidance@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    visit new_vault_item_path(kind: "login")
    fill_in "Title", with: "Filter target"
    fill_in "Username", with: "filter@example.test"
    fill_in "Secret / password", with: "fake-filter-secret"
    fill_in "Url", with: "https://example.test"
    click_button "Encrypt and save"

    visit vault_items_path
    assert_select "Filter by type", selected: "All types"
    assert_select "Filter by state", selected: "All states"
    assert_select "Filter by tag", selected: "All tags"

    select "Login", from: "Filter by type"
    assert_select "Filter by type", selected: "Login"
    click_button "Search"
    assert_select "Filter by type", selected: "Login"
    assert_text "Filters active"
    assert_link "Clear filters", href: vault_items_path
    assert_text "Filter target"
  end
end
