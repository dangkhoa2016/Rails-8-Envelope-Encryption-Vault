require "test_helper"

class AuditListEventsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "audit-list@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
    @other_user = User.create!(
      email_address: "audit-other@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
  end

  test "filters actions and remains scoped to the current user" do
    2.times { AuditEvent.create!(user: @user, action: "vault_item.created", metadata: {}) }
    AuditEvent.create!(user: @user, action: "vault_item.updated", metadata: {})
    AuditEvent.create!(user: @other_user, action: "vault_item.created", metadata: {})

    result = Audit::ListEvents.call(user: @user, action: "vault_item.created")

    assert_equal 2, result.total
    assert result.events.all? { |event| event.user_id == @user.id }
    assert_equal [ "vault_item.created" ], result.events.map(&:action).uniq
    assert_includes result.available_actions, "vault_item.updated"
  end

  test "paginates after filtering" do
    5.times { AuditEvent.create!(user: @user, action: "vault_item.created", metadata: {}) }
    3.times { AuditEvent.create!(user: @user, action: "vault_item.updated", metadata: {}) }

    first = Audit::ListEvents.call(user: @user, action: "vault_item.created", page: 1, per_page: 2)
    third = Audit::ListEvents.call(user: @user, action: "vault_item.created", page: 3, per_page: 2)

    assert_equal 5, first.total
    assert_equal 3, first.total_pages
    assert_equal 2, first.events.length
    assert_equal 1, third.events.length
  end

  test "filters by friendly category while preserving raw action filtering" do
    AuditEvent.create!(user: @user, action: "user.password_changed", metadata: {})
    AuditEvent.create!(user: @user, action: "user.login_succeeded", metadata: {})
    AuditEvent.create!(user: @user, action: "vault_item.created", metadata: {})
    AuditEvent.create!(user: @user, action: "vault_item.updated", metadata: {})

    vault = Audit::ListEvents.call(user: @user, category: "Vault")
    account = Audit::ListEvents.call(user: @user, category: "Account")
    combined = Audit::ListEvents.call(user: @user, category: "Vault", action: "vault_item.updated")

    assert_equal %w[vault_item.created vault_item.updated].sort, vault.events.map(&:action).uniq.sort
    assert_equal [ "user.password_changed" ], account.events.map(&:action).uniq
    assert_equal [ "vault_item.updated" ], combined.events.map(&:action).uniq
    assert_includes vault.available_categories, "Vault"
    assert_equal "Vault", vault.selected_category
    assert_equal %w[vault_item.created vault_item.updated], vault.available_actions.sort
    assert_equal 2, vault.category_counts.fetch("Vault")
    assert_equal 1, vault.category_counts.fetch("Account")
    assert_equal 1, vault.category_counts.fetch("Sessions")
  end


  test "filters future unmapped actions through Other category" do
    AuditEvent.create!(user: @user, action: "future.security_event", metadata: {})
    AuditEvent.create!(user: @user, action: "vault_item.created", metadata: {})

    result = Audit::ListEvents.call(user: @user, category: "Other")

    assert_equal [ "future.security_event" ], result.events.map(&:action)
    assert_includes result.available_categories, "Other"
  end
end
