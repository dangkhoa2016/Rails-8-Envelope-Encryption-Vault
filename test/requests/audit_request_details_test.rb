require "test_helper"

class AuditRequestDetailsRequestTest < ActionDispatch::IntegrationTest
  def build_user(email)
    User.create!(email_address: email, password: "long-password-1234",
                 password_confirmation: "long-password-1234")
  end

  def log_in(user, agent: "Mozilla/5.0 Chrome/125.0", ip: "203.0.113.15")
    post session_path,
         params: { email_address: user.email_address, password: "long-password-1234" },
         headers: { "User-Agent" => agent, "REMOTE_ADDR" => ip }
    assert_response :redirect
  end

  test "successful authentication saves and renders allowlisted request context" do
    user = build_user("audit-browser-request@example.test")
    log_in(user)
    event = user.audit_events.find_by!(action: "user.login_succeeded")

    assert_equal "203.0.113.15", event.metadata["ip_address"]
    assert_equal "POST", event.metadata["http_method"]
    assert_equal "/session", event.metadata["request_path"]
    assert_includes event.metadata["user_agent"], "Chrome/125"
    assert_equal %w[http_method ip_address request_path user_agent], event.metadata.keys.sort

    get audit_events_path(category: "Sessions")
    assert_response :success
    assert_select "[data-audit-action='user.login_succeeded']" do
      assert_select "dt", text: "IP address"
      assert_select "dd", text: "203.0.113.15"
      assert_select "dt", text: "User-Agent header"
      assert_select "dd", text: /Chrome\/125/
      assert_select "dt", text: "Browser"
    end
  end

  test "login failure remains unattributed and excludes credentials from the audit" do
    user = build_user("audit-failed-login@example.test")
    post session_path,
         params: { email_address: user.email_address, password: "fake-password-cannot-appear" },
         headers: { "User-Agent" => "Mozilla/5.0 Chrome/125.0", "REMOTE_ADDR" => "203.0.113.15" }
    assert_response :redirect
    event = AuditEvent.where(action: "user.login_failed").order(:created_at).last
    assert_nil event.user_id
    assert_equal "203.0.113.15", event.metadata["ip_address"]
    refute_includes event.metadata.to_json, "fake-password-cannot-appear"
    refute_includes event.metadata.to_json, user.email_address

    log_in(user)
    get audit_events_path(category: "Sessions")
    assert_response :success
    assert_select "[data-audit-action='user.login_failed']", false
  end

  test "vault audit hyperlinks require a currently owned item including archived items" do
    user = build_user("audit-owned-item@example.test")
    other = build_user("audit-other-item@example.test")
    log_in(user)

    owned = VaultItem.create!(user: user, kind: "secure_note")
    archived = VaultItem.create!(user: user, kind: "secure_note", archived_at: Time.current)
    foreign = VaultItem.create!(user: other, kind: "secure_note")
    AuditEvent.create!(user: user, vault_item: owned, action: "vault_item.created", metadata: {})
    AuditEvent.create!(user: user, vault_item: archived, action: "vault_item.archived", metadata: {})
    AuditEvent.create!(user: user, vault_item: foreign, action: "vault_item.revealed", metadata: {})
    AuditEvent.create!(user: user, action: "vault_item.created", metadata: {})

    get audit_events_path(category: "Vault")
    assert_response :success
    assert_select "a[href='#{vault_item_path(owned)}']", count: 1
    assert_select "a[href='#{vault_item_path(archived)}']", count: 1
    assert_select "a[href='#{vault_item_path(foreign)}']", false
    assert_select "p", text: "Vault item no longer available"
  end

  test "audit endpoint requires authentication" do
    get audit_events_path
    assert_response :redirect
  end
end
