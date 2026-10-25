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

  test "listing favorite and unfavorite Turbo Streams replace only their star and toast" do
    target = "listing_favorite_control_vault_item_#{@item.id}"
    params = { source: "listing", page: "4", status: "active" }
    headers = { "ACCEPT" => "text/vnd.turbo-stream.html" }

    post favorite_vault_item_path(@item), params: params, headers: headers
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='replace'][target='#{target}']", 1
    assert_select "##{target} button[aria-label='Remove from favorites']", 1
    assert_select "##{target} input[name='page'][value='4']", 1
    assert_select "turbo-stream[action='update'][target='toast_notifications'] [role='status']",
      text: /Added to favorites\./
    assert_select "turbo-stream[target='vault_listing']", 0
    assert @item.reload.favorite?

    post unfavorite_vault_item_path(@item), params: params, headers: headers
    assert_response :success
    assert_select "turbo-stream[action='replace'][target='#{target}']", 1
    assert_select "##{target} button[aria-label='Add to favorites']", 1
    assert_select "turbo-stream[action='update'][target='toast_notifications'] [role='status']",
      text: /Removed from favorites\./
    assert_not @item.reload.favorite?
  end

  test "listing HTML fallback preserves safe page and session-scoped search filter" do
    post search_vault_items_path, params: {
      q: "Private favorite", kind: "login", status: "active", tag: "test"
    }
    assert_response :see_other
    filter = Rack::Utils.parse_nested_query(URI.parse(response.location).query).fetch("filter")

    post favorite_vault_item_path(@item),
      params: { source: "listing", page: "4", filter:, status: "active" }
    assert_response :see_other
    destination = URI.parse(response.location)
    assert_equal "/vault_items", destination.path
    assert_equal "4", Rack::Utils.parse_nested_query(destination.query)["page"]
    assert_equal filter, Rack::Utils.parse_nested_query(destination.query)["filter"]
    refute_includes response.location, "Private"
    refute_includes response.location, "test"
    assert @item.reload.favorite?

    post unfavorite_vault_item_path(@item),
      params: { source: "listing", page: "4", filter:, status: "active" }
    assert_response :see_other
    assert_equal filter, Rack::Utils.parse_nested_query(URI.parse(response.location).query)["filter"]
    assert_not @item.reload.favorite?
  end

  test "unfavorite in Favorites-only filter streams refreshed listing without full navigation" do
    @item.update!(favorite: true)
    post search_vault_items_path, params: { favorite: "1", status: "active" }
    assert_response :see_other
    filter = Rack::Utils.parse_nested_query(URI.parse(response.location).query).fetch("filter")

    post unfavorite_vault_item_path(@item),
      params: { source: "listing", filter:, page: "1", status: "active" },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_select "turbo-stream[action='replace'][target='vault_listing']", 1
    assert_select "turbo-stream[action='update'][target='toast_notifications'] [role='status']", 1
    assert_select "turbo-stream[target='listing_favorite_control_vault_item_#{@item.id}']", 0
    assert_not @item.reload.favorite?
  end

  test "listing fallback does not honor external or malformed navigation parameters" do
    post favorite_vault_item_path(@item),
      params: { source: "listing", page: "javascript:alert(1)", filter: "unknown", status: "unsafe",
                return_to: "https://other.example/steal" }
    assert_response :see_other
    assert_redirected_to vault_items_path(page: 1, sort: "favorite", direction: "desc")
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
