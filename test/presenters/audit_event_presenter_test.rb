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

  test "classifies actions into stable friendly categories" do
    assert_equal "Vault", AuditEventPresenter.category_for("vault_item.created")
    assert_equal "MFA", AuditEventPresenter.category_for("user.mfa_enabled")
    assert_equal "Keys", AuditEventPresenter.category_for("key.rotation_completed")
    assert_equal "Other", AuditEventPresenter.category_for("future.event")
  end
end
