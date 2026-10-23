require "test_helper"

class VaultFavoriteUxTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "favorite-detail-request@example.test",
      password: "synthetic-password-1234",
      password_confirmation: "synthetic-password-1234"
    )
    post session_path, params: {
      email_address: @user.email_address, password: "synthetic-password-1234"
    }
    assert_redirected_to root_path

    @item = Vault::CreateItem.call(user: @user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Private favorite detail",
      "username" => "example@example.test", "password" => "synthetic-secret",
      "url" => "https://example.test", "notes" => "", "tags" => %w[test]
    })
  end

  test "detail favorite and unfavorite replace only the control with Turbo Stream" do
    post favorite_vault_item_path(@item), params: { source: "detail" },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select 'turbo-stream[action="replace"][target="vault_favorite_control"]', 1
    assert_select '#vault_favorite_control button[aria-label="Remove from favorites"]', 1
    assert_select '#vault_favorite_control [role="status"]', 0
    assert_select 'turbo-stream[action="update"][target="toast_notifications"] [role="status"]', text: /Added to favorites\./
    assert @item.reload.favorite?
    assert_equal 1, AuditEvent.where(user: @user, vault_item: @item, action: "vault_item.favorited").count

    post unfavorite_vault_item_path(@item), params: { source: "detail" },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_select 'turbo-stream[action="replace"][target="vault_favorite_control"]', 1
    assert_select '#vault_favorite_control button[aria-label="Add to favorites"]', 1
    assert_select '#vault_favorite_control [role="status"]', 0
    assert_select 'turbo-stream[action="update"][target="toast_notifications"] [role="status"]', text: /Removed from favorites\./
    assert_not @item.reload.favorite?
    assert_equal 1, AuditEvent.where(user: @user, vault_item: @item, action: "vault_item.unfavorited").count
  end

  test "without Turbo both detail actions redirect back to the same item" do
    post favorite_vault_item_path(@item), params: { source: "detail" }
    assert_response :see_other
    assert_redirected_to vault_item_path(@item)
    follow_redirect!
    assert_response :success
    assert_select '#vault_favorite_control button[aria-label="Remove from favorites"]', 1

    post unfavorite_vault_item_path(@item), params: { source: "detail" }
    assert_response :see_other
    assert_redirected_to vault_item_path(@item)
    follow_redirect!
    assert_response :success
    assert_select '#vault_favorite_control button[aria-label="Add to favorites"]', 1
  end

  test "favorites submitted from the listing retain list navigation" do
    post favorite_vault_item_path(@item)
    assert_response :see_other
    assert_redirected_to vault_items_path
    assert @item.reload.favorite?

    post unfavorite_vault_item_path(@item), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    assert_response :see_other
    assert_redirected_to vault_items_path
    assert_not @item.reload.favorite?
  end

  test "the same global toast works on the detail and the sign-in screen" do
    post favorite_vault_item_path(@item), params: { source: "detail" }
    assert_redirected_to vault_item_path(@item)
    follow_redirect!
    assert_select '#toast_notifications [data-controller="flash"][role="status"]',
      text: /Added to favorites\./
    assert_select '#vault_favorite_control [role="status"]', 0

    delete session_path
    post session_path, params: {
      email_address: @user.email_address, password: "incorrect-password"
    }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select '#toast_notifications [data-controller="flash"][role="alert"]',
      text: /Email or password is incorrect\./
    assert_select 'main [role="alert"]', 0
  end

  test "another user cannot use detail origin to favorite or unfavorite this item" do
    post session_path, params: {
      email_address: User.create!(
        email_address: "favorite-attacker@example.test",
        password: "synthetic-password-1234",
        password_confirmation: "synthetic-password-1234"
      ).email_address,
      password: "synthetic-password-1234"
    }

    post favorite_vault_item_path(@item), params: { source: "detail" }
    assert_response :not_found
    post unfavorite_vault_item_path(@item), params: { source: "detail" }
    assert_response :not_found
    assert_not @item.reload.favorite?
  end
end
