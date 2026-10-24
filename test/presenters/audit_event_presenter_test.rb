require "test_helper"

class AuditEventPresenterTest < ActiveSupport::TestCase
  test "maps known raw actions to friendly copy" do
    presenter = AuditEventPresenter.for("vault_item.revealed")

    assert_equal "Secret revealed", presenter.title
    assert_match(/decrypted/i, presenter.description)
    assert_equal "vault_item.revealed", presenter.action
  end

  test "falls back safely for future action identifiers" do
    presenter = AuditEventPresenter.for("future.security_event")

    assert_equal "Future Security Event", presenter.title
    assert_equal "A security-relevant vault event was recorded.", presenter.description
  end

  test "renders only explicitly allowlisted safe metadata" do
    event = AuditEvent.new(
      action: "user.password_changed",
      metadata: {
        "session_rotated" => true,
        "other_sessions_revoked" => true,
        "unexpected_field" => "must-not-render"
      },
      request_id: "req-1234567890abcdef",
      vault_item_id: SecureRandom.uuid
    )
    presenter = AuditEventPresenter.for_event(event)

    assert_equal [ [ "Other sessions revoked", "Yes" ], [ "Session rotated", "Yes" ] ], presenter.safe_context
    assert_equal "req-12345678", presenter.correlation_id
    refute_includes presenter.safe_context.flatten, "must-not-render"
  end

  test "does not expose metadata for actions without a context allowlist" do
    event = AuditEvent.new(action: "vault_item.revealed", metadata: { "kind" => "login" })

    assert_empty AuditEventPresenter.for_event(event).safe_context
  end

  test "provides explicit outcomes without inferring unknown events are successful" do
    assert_equal "failed", AuditEventPresenter.for("user.mfa_failed").outcome
    assert_equal "completed", AuditEventPresenter.for("vault_item.created").outcome
    assert_equal "recorded", AuditEventPresenter.for("future.unknown").outcome
    assert_equal "recorded", AuditEventPresenter.for("key.rotation_started").outcome
    assert AuditEventPresenter.for("vault_item.revealed").sensitive?
    refute AuditEventPresenter.for("vault_item.favorited").sensitive?
  end

  test "presents bounded request headers and a friendly device description only for session events" do
    event = AuditEvent.new(action: "user.login_succeeded", metadata: {
      "user_agent" => "Mozilla/5.0 (Windows NT 10.0) Chrome/125.0",
      "ip_address" => "203.0.113.15", "request_path" => "/session",
      "http_method" => "POST", "bad_data" => "NEVER-SHOW"
    })
    fields = AuditEventPresenter.for_event(event).safe_context.to_h
    assert_equal "Chrome", fields.fetch("Browser")
    assert_equal "Windows", fields.fetch("Operating system")
    assert_equal "203.0.113.15", fields.fetch("IP address")
    assert_equal "POST", fields.fetch("Request method")
    assert_equal "/session", fields.fetch("Request path")
    assert_includes fields.fetch("User-Agent header"), "Chrome/125"
    refute_includes fields.values, "NEVER-SHOW"

    other = AuditEvent.new(action: "vault_item.created", metadata: event.metadata)
    refute_includes AuditEventPresenter.for_event(other).safe_context.flatten, "203.0.113.15"
  end

  test "classifies actions into stable friendly categories" do
    assert_equal "Vault", AuditEventPresenter.category_for("vault_item.created")
    assert_equal "MFA", AuditEventPresenter.category_for("user.mfa_enabled")
    assert_equal "Keys", AuditEventPresenter.category_for("key.rotation_completed")
    assert_equal "Other", AuditEventPresenter.category_for("future.event")
  end
end
