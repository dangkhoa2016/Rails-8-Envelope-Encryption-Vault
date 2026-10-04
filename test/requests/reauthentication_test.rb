require "test_helper"

class ReauthenticationTest < ActionDispatch::IntegrationTest
  test "reveal requires recent reauthentication when verification window is stale" do
    user = User.create!(email_address: "reauth@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    item = Vault::CreateItem.call(user: user, kind: "login", payload: { "schema" => "vault.login.v1", "title" => "private" })
    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    user.sessions.last.update_column(:reauthenticated_at, 1.hour.ago)

    post vault_item_reveal_path(item), headers: { "Turbo-Frame" => "revealed_secret" }
    assert_response :unauthorized
    assert_includes response.body, "Confirm identity"
  end

  test "successful reauthentication rotates server side session" do
    user = User.create!(email_address: "rotate-session@example.test", password: "long-password-1234", password_confirmation: "long-password-1234")
    post session_path, params: { email_address: user.email_address, password: "long-password-1234" }
    old_session = user.sessions.order(:created_at).last
    old_session.update_column(:reauthenticated_at, 1.hour.ago)

    post reauthentication_path, params: { password: "long-password-1234" }
    assert_response :redirect

    old_session.reload
    assert old_session.revoked_at.present?
    assert_operator user.sessions.count, :>=, 2
    assert user.sessions.order(:created_at).last.active?
  end
end
