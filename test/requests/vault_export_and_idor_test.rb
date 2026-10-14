require "test_helper"

class VaultExportAndIdorTest < ActionDispatch::IntegrationTest
  TEST_PASSWORD = "long-password-1234"

  def create_user(email)
    User.create!(email_address: email, password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: TEST_PASSWORD }
    assert_response :redirect
  end

  test "environment export returns dotenv attachment with no-store headers" do
    user = create_user("export-owner@example.test")
    item = Vault::CreateItem.call(
      user: user,
      kind: "environment",
      payload: {
        "schema" => "vault.environment.v1",
        "title" => "Demo environment",
        "entries" => [
          { "key" => "DEMO_API_KEY", "value" => "fake-export-value" },
          { "key" => "FEATURE_FLAG", "value" => "true" }
        ]
      }
    )
    sign_in(user)

    post vault_item_export_path(item)

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "no-cache", response.headers["Pragma"]
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], "vault-#{item.id}.env"
    assert_includes response.body, "DEMO_API_KEY=fake-export-value"
    assert_includes response.body, "FEATURE_FLAG=true"
    assert AuditEvent.where(user: user, vault_item: item, action: "vault_item.exported").exists?
  end

  test "one user cannot reach another users sensitive vault endpoints" do
    owner = create_user("idor-owner@example.test")
    attacker = create_user("idor-attacker@example.test")
    item = Vault::CreateItem.call(
      user: owner,
      kind: "environment",
      payload: {
        "schema" => "vault.environment.v1",
        "title" => "Private env",
        "entries" => [ { "key" => "PRIVATE", "value" => "fake-private-value" } ]
      }
    )
    version = item.current_version
    sign_in(attacker)

    get vault_item_path(item)
    assert_response :not_found

    post vault_item_reveal_path(item), headers: { "Turbo-Frame" => "revealed_secret" }
    assert_response :not_found

    post vault_item_export_path(item)
    assert_response :not_found

    get vault_item_versions_path(item)
    assert_response :not_found

    post restore_vault_item_version_path(item, version)
    assert_response :not_found
  end
end
