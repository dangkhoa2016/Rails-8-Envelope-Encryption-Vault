require "application_system_test_case"

class AuditPaginationTest < ApplicationSystemTestCase
  test "audit listing paginates with GET and preserves category and action filters" do
    user = create_system_user("audit-pagy-browser@example.test")
    sign_in_system_user(user)

    26.times do |index|
      AuditEvent.create!(
        user: user, action: "vault_item.created",
        metadata: {}, created_at: Time.current + index.seconds
      )
    end
    2.times { AuditEvent.create!(user: user, action: "vault_item.updated", metadata: {}) }

    visit audit_events_path(category: "Vault", event_action: "vault_item.created")
    assert_text "26 matching event(s)"
    assert_text "Page 1 of 3"
    assert_selector "nav[aria-label='Audit pagination'] a[rel='next']", count: 1

    click_link "Next", match: :first
    assert_text "Page 2 of 3"
    assert_equal "/audit_events", URI.parse(page.current_url).path
    assert_includes page.current_url, "page=2"
    assert_includes page.current_url, "category=Vault"
    assert_includes page.current_url, "event_action=vault_item.created"
    assert_select "Category", selected: "Vault"
    assert_select "Action", selected: "Vault item created"
    assert_selector "[data-audit-action='vault_item.created']", count: 10
    assert_no_selector "[data-audit-action='vault_item.updated']"

    click_link "Next", match: :first
    assert_text "Page 3 of 3"
    assert_selector "[data-audit-action='vault_item.created']", count: 6
    click_link "Previous"
    assert_text "Page 2 of 3"
  end
  test "category choice instantly refreshes Action and clears incompatible selection" do
    user = create_system_user("audit-action-select@example.test")
    sign_in_system_user(user)
    AuditEvent.create!(user: user, action: "vault_item.created", metadata: {})
    AuditEvent.create!(user: user, action: "vault_item.updated", metadata: {})
    AuditEvent.create!(user: user, action: "user.login_succeeded", metadata: {})

    visit audit_events_path
    execute_script("window.__auditNoReload = true")
    select "Vault", from: "Category"
    assert_selector "select#event_action option[value='vault_item.created']"
    assert_selector "select#event_action option[value='vault_item.updated']"
    assert_no_selector "select#event_action option[value='user.login_succeeded']"
    assert_equal true, evaluate_script("window.__auditNoReload")
    select "Vault item updated", from: "Action"
    click_button "Filter"
    assert_select "Category", selected: "Vault"
    assert_select "Action", selected: "Vault item updated"
    assert_selector "[data-audit-action='vault_item.updated']"
    assert_no_selector "[data-audit-action='vault_item.created']"

    select "Sessions", from: "Category"
    assert_selector "select#event_action option[value='user.login_succeeded']"
    assert_no_selector "select#event_action option[value='vault_item.updated']"
    assert_select "Action", selected: "All actions"
    select "Signed in", from: "Action"
    click_button "Filter"
    assert_select "Category", selected: "Sessions"
    assert_select "Action", selected: "Signed in"
  end
end
