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
  test "time range and outcome filters preserve pagination and account-scoped totals" do
    user = create_system_user("audit-timeline-filter@example.test")
    other = create_system_user("audit-timeline-other@example.test")
    sign_in_system_user(user)
    14.times { AuditEvent.create!(user: user, action: "vault_item.revealed", metadata: {}) }
    2.times { AuditEvent.create!(user: user, action: "user.mfa_failed", metadata: {}) }
    AuditEvent.create!(user: other, action: "user.mfa_failed", metadata: {})
    AuditEvent.create!(action: "user.login_failed", metadata: {})

    visit audit_events_path
    assert_text "17 matching event(s)"
    assert_selector "[data-audit-summary='total']", text: "17" # includes successful login
    assert_selector "[data-audit-summary='failed']", text: "2"
    assert_text "Account-level scope"
    assert_selector "section[aria-label='Audit timeline']"
    assert_selector "details summary", minimum: 0

    select "Vault", from: "Category"
    select "Completed", from: "Outcome"
    select "Past 7 days", from: "Time range"
    click_button "Filter"
    assert_select "Category", selected: "Vault"
    assert_select "Outcome", selected: "Completed"
    assert_text "14 matching event(s)"
    assert_selector "[data-audit-action='vault_item.revealed']", count: 10
    click_link "Next", match: :first
    assert_selector "[data-audit-action='vault_item.revealed']", count: 4
    assert_includes page.current_url, "outcome=completed"
    assert_includes page.current_url, "range=7"
    assert_no_selector "[data-audit-action='user.mfa_failed']"
    click_link "Reset"
    # Turbo navigation is asynchronous. Verify the unfiltered GET and fresh
    # account-scoped result set before inspecting form state after reset.
    assert_current_path audit_events_path, ignore_query: false
    assert_text "17 matching event(s)"
    assert_select "Time range", selected: "Past 30 days"
    assert_select "Outcome", selected: "All outcomes"
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
