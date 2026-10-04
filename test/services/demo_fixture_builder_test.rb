require "test_helper"

class DemoFixtureBuilderTest < ActiveSupport::TestCase
  setup do
    @previous_demo_mode = ENV["DEMO_MODE"]
    ENV["DEMO_MODE"] = "true"
  end

  teardown do
    ENV["DEMO_MODE"] = @previous_demo_mode
  end

  test "creates an encrypted synthetic showcase fixture idempotently" do
    result = Demo::FixtureBuilder.call(password: "demo-fixture-password-1234", reset: true)
    user = result.user

    assert_equal Demo::FixtureBuilder::DEMO_EMAIL, user.email_address
    assert_equal 6, user.vault_items.count
    assert_equal 7, VaultItemVersion.where(vault_item_id: user.vault_items.select(:id)).count
    assert user.vault_items.where(favorite: true).exists?
    assert user.audit_events.where(action: "vault_item.created").exists?

    titles = user.vault_items.map { |item| Vault::RevealItem.call(user:, item:, audit: false).fetch("title") }
    assert_includes titles, "Acme Analytics"
    assert_includes titles, "Demo PostgreSQL"

    rerun = Demo::FixtureBuilder.call(password: "demo-fixture-password-1234")
    assert_empty rerun.items
    assert_equal 6, user.vault_items.reload.count
  end

  test "requires demo mode and a sufficiently long password" do
    ENV["DEMO_MODE"] = "false"

    error = assert_raises(ArgumentError) do
      Demo::FixtureBuilder.call(password: "demo-fixture-password-1234")
    end
    assert_equal "Demo fixture requires DEMO_MODE=true.", error.message

    ENV["DEMO_MODE"] = "true"
    assert_raises(ArgumentError) { Demo::FixtureBuilder.call(password: "too-short") }
  end
end
