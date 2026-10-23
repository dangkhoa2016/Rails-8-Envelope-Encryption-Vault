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

  test "vault creation actions have distinct hierarchy and interactive cursor" do
    user = create_system_user("vault-actions@example.test")
    sign_in_system_user(user)

    Vault::CreateItem.call(user: user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Action layout sample",
      "username" => "sample@example.test", "password" => "demo-only",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })
    visit vault_items_path

    assert_selector "header a[href='#{new_vault_item_path}']", text: "New item"
    assert_selector "main section > div:last-child a[href='#{new_vault_item_path}']", text: "New encrypted item"
    assert_equal "pointer", evaluate_script(
      "getComputedStyle(document.querySelector('header a[href=\\\"#{new_vault_item_path}\\\"]')).cursor"
    )
    assert_equal "pointer", evaluate_script(
      "getComputedStyle(document.querySelector('main section > div:last-child a')).cursor"
    )
    assert_equal "pointer", evaluate_script(
      "getComputedStyle(document.querySelector('input[type=submit]')).cursor"
    )
  end

  test "vault search updates in place and GET pagination never reveals title filters" do
    user = create_system_user("vault-paging-browser@example.test")
    sign_in_system_user(user)

    8.times do |index|
      item = Vault::CreateItem.call(user: user, kind: "login", payload: {
        "schema" => "vault.login.v1", "title" => format("Paging sample %02d", index + 1),
        "username" => "synthetic@example.test", "password" => "fake-demo-only",
        "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
      })
      item.update_columns(updated_at: Time.current + (index + 1).minutes)
    end

    visit vault_items_path
    fill_in "Search encrypted titles", with: "Paging sample"
    select "Login", from: "Filter by type"
    execute_script("window.__vaultNoReload = true")
    click_button "Search"

    assert_equal true, evaluate_script("window.__vaultNoReload")
    assert_text "Page 1 of 2"
    assert_equal "/vault_items", URI.parse(page.current_url).path
    current_params = Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)
    assert_equal "1", current_params.fetch("page")
    assert_equal "login", current_params.fetch("kind")
    assert_match /\A[0-9a-f]{32}\z/, current_params.fetch("filter")
    assert_nil current_params["q"]
    assert_nil current_params["tag"]
    assert_text "Paging sample 08"
    assert_no_text "Paging sample 01"
    assert_selector "nav[aria-label='Vault pagination'] a[rel='next'][href*='page=2']", count: 1
    click_link "Next"
    assert_text "Page 2 of 2"
    next_params = Rack::Utils.parse_nested_query(URI.parse(page.current_url).query)
    assert_equal "2", next_params.fetch("page")
    assert_equal current_params.fetch("filter"), next_params.fetch("filter")
    assert_equal current_params.fetch("kind"), next_params.fetch("kind")
    assert_text "Paging sample 01"
    assert_no_text "Paging sample 08"
    assert_select "Filter by type", selected: "Login"
    assert_field "Search encrypted titles", with: "Paging sample"
    refute_includes page.current_url, "Paging"
    assert_selector "nav[aria-label='Vault pagination'] a[rel='prev'][href*='page=1']", count: 1
    click_link "Previous"
    assert_text "Page 1 of 2"
    assert_equal current_params.fetch("filter"), Rack::Utils.parse_nested_query(URI.parse(page.current_url).query).fetch("filter")
    assert_text "Paging sample 08"
    assert_no_text "Paging sample 01"
    refute_includes page.current_url, "Paging"
    click_link "Clear filters"
    assert_current_path vault_items_path
    assert_no_text "Filters active"
    assert_field "Search encrypted titles", with: ""
  end

  test "browser back and forward restore a Vault search URL and its private filters" do
    user = create_system_user("vault-history-browser@example.test")
    sign_in_system_user(user)
    Vault::CreateItem.call(user: user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "History sample secret",
      "username" => "synthetic@example.test", "password" => "synthetic",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })

    visit vault_items_path
    fill_in "Search encrypted titles", with: "History sample"
    click_button "Search"
    assert_text "Filters active"
    filtered_url = page.current_url
    assert_includes filtered_url, "filter="
    refute_includes filtered_url, "History"

    page.go_back
    assert_current_path vault_items_path
    assert_field "Search encrypted titles", with: ""
    assert_no_text "Filters active"

    page.go_forward
    assert_current_path filtered_url
    assert_field "Search encrypted titles", with: "History sample"
    assert_text "Filters active"
  end

  test "dashboard creation action matches the secondary vault action below content" do
    user = create_system_user("dashboard-cta-hierarchy@example.test")
    sign_in_system_user(user)

    assert_selector "header a[href='#{new_vault_item_path}']", text: "New item"
    assert_no_selector "main > section > div:first-child a[href='#{new_vault_item_path}']"
    assert_selector "main > section > div:last-child a[data-create-role='secondary']", text: "New encrypted item"
    dashboard_action = find("main a[data-create-role='secondary']")
    dashboard_style = dashboard_action[:class]
    primary_style = find("header a[href='#{new_vault_item_path}']")[:class]
    assert_includes dashboard_style, "border-indigo-400/40"
    assert_includes dashboard_style, "bg-indigo-400/10"
    assert_not_equal primary_style, dashboard_style
    assert_equal "pointer", evaluate_script(
      "getComputedStyle(document.querySelector('main a[data-create-role=secondary]')).cursor"
    )

    Vault::CreateItem.call(user: user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Dashboard action sample",
      "username" => "synthetic@example.test", "password" => "fake-demo-only",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })
    visit vault_items_path
    assert_selector "main > section > div:last-child a[data-create-role='secondary']", text: "New encrypted item"
    assert_equal dashboard_style, find("main a[data-create-role='secondary']")[:class]
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
    assert_select "Filter by state", selected: "Active"
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
