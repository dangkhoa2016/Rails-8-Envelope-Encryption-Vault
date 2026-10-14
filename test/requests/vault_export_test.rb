require "test_helper"

class VaultExportTest < ActionDispatch::IntegrationTest
  test "environment export returns plaintext only in the response and is never cacheable" do
    user = User.create!(email_address: "export@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    item = Vault::CreateItem.call(
      user: user,
      kind: "environment",
      payload: {
        "schema" => "vault.environment.v1",
        "title" => "demo env",
        "environment" => "test",
        "entries" => [
          { "key" => "API_TOKEN", "value" => "fake-token-value" },
          { "key" => "DATABASE_URL", "value" => "postgresql://example.test/demo" }
        ],
        "notes" => ""
      }
    )

    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    assert_redirected_to root_path

    post vault_item_export_path(item)
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.headers["Cache-Control"], "no-store"
    assert_equal "no-cache", response.headers["Pragma"]
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_includes response.body, "API_TOKEN=fake-token-value"
    assert_includes response.body, "DATABASE_URL=postgresql://example.test/demo"
    assert AuditEvent.where(user: user, vault_item: item, action: "vault_item.exported").exists?
  end
end
