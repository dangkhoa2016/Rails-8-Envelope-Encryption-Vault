require "test_helper"

class VaultAuthorizationTest < ActionDispatch::IntegrationTest
  def create_user(email)
    User.create!(email_address: email, password: "long-password-1234", password_confirmation: "long-password-1234")
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    follow_redirect! if response.redirect?
  end

  test "one user cannot access or change another users vault item" do
    owner = create_user("owner@example.test")
    attacker = create_user("attacker@example.test")
    item = Vault::CreateItem.call(user: owner, kind: "login", payload: { "schema" => "vault.login.v1", "title" => "private" })
    sign_in(attacker)
    get vault_item_path(item)
    assert_response :not_found

    post archive_vault_item_path(item)
    assert_response :not_found

    post unarchive_vault_item_path(item)
    assert_response :not_found
  end

  test "one user cannot reveal export or restore another users vault item" do
    owner = create_user("sensitive-owner@example.test")
    attacker = create_user("sensitive-attacker@example.test")
    item = Vault::CreateItem.call(
      user: owner,
      kind: "environment",
      payload: {
        "schema" => "vault.environment.v1",
        "title" => "private env",
        "environment" => "test",
        "entries" => [ { "key" => "TOKEN", "value" => "fake-value" } ],
        "notes" => ""
      }
    )
    version = item.current_version

    sign_in(attacker)

    post vault_item_reveal_path(item), headers: { "Turbo-Frame" => "revealed_secret" }
    assert_response :not_found

    post vault_item_export_path(item)
    assert_response :not_found

    post restore_vault_item_version_path(item, version)
    assert_response :not_found
  end
end
