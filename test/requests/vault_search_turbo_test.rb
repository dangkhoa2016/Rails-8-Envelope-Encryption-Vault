require "test_helper"

class VaultSearchTurboTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "turbo-search@example.test",
      password: "test-only-passphrase-1234",
      password_confirmation: "test-only-passphrase-1234"
    )
    post session_path, params: {
      email_address: @user.email_address, password: "test-only-passphrase-1234"
    }
    assert_redirected_to root_path
    Vault::CreateItem.call(user: @user, kind: "login", payload: {
      "schema" => "vault.login.v1", "title" => "Private sample title",
      "username" => "sample@example.test", "password" => "synthetic",
      "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
    })
  end

  test "Turbo Stream returns updated listing without redirect" do
    6.times do |index|
      Vault::CreateItem.call(user: @user, kind: "login", payload: {
        "schema" => "vault.login.v1", "title" => "Private sample title #{index + 2}",
        "username" => "sample@example.test", "password" => "synthetic",
        "url" => "https://example.test", "notes" => "", "tags" => %w[demo]
      })
    end
    post search_vault_items_path,
      params: { q: "Private sample title", kind: "login", status: "all" },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select 'turbo-stream[action="replace"][target="vault_listing"]'
    assert_select 'section#vault_listing[data-vault-search-updated-value="true"]'
    assert_select 'nav[aria-label="Vault pagination"] a[rel="next"]', 1
    listing_url = response.body.match(/data-vault-search-list-url-value="([^"]+)"/)[1]
    listing_url = CGI.unescapeHTML(listing_url)
    query = Rack::Utils.parse_nested_query(URI.parse(listing_url).query)
    assert_equal "1", query.fetch("page")
    assert_equal "login", query.fetch("kind")
    assert_match /\A[0-9a-f]{32}\z/, query.fetch("filter")
    assert_no_match(/Private|q=|tag=/, listing_url)
    assert_select 'nav[aria-label="Vault pagination"] a[rel="next"][href*="filter="]'

    get listing_url
    assert_response :success
    assert_select 'input[type="search"][value="Private sample title"]'
    assert_select 'nav[aria-label="Vault pagination"] a[rel="next"][href*="filter="]'
    get vault_items_path(filter: query.fetch("filter"), page: 2)
    assert_response :success
    assert_select 'input[type="search"][value="Private sample title"]'
  end

  test "plain HTML retains the POST to GET redirect fallback" do
    post search_vault_items_path, params: { q: "Private sample title" }
    assert_response :see_other
    redirect_uri = URI.parse(response.location)
    assert_equal vault_items_path, redirect_uri.path
    query = Rack::Utils.parse_nested_query(redirect_uri.query)
    assert_equal "1", query.fetch("page")
    assert_match /\A[0-9a-f]{32}\z/, query.fetch("filter")
    assert_no_match(/Private/, response.location)
    follow_redirect!
    assert_response :success
    assert_select 'input[type="search"][value="Private sample title"]'
  end

  test "large Unicode searches do not overflow encrypted cookie sessions" do
    5.times do |i|
      query = "🔐" * 199 + i.to_s
      post search_vault_items_path, params: { q: query, tag: "🔑" * 80 }
      assert_response :see_other
      saved_url = response.location
      assert_no_match(/🔐|🔑/, saved_url)
      get saved_url
      assert_response :success
      assert_select 'input[type="search"]', value: query
    end
  end

  test "prior search URLs retain their own filters in the same session" do
    post search_vault_items_path, params: { q: "Private sample title", kind: "login", tag: "demo" }
    first_url = response.location
    post search_vault_items_path, params: { q: "nonexistent title", kind: "login" }
    second_url = response.location
    assert_not_equal first_url, second_url
    assert_no_match(/Private|nonexistent|demo/, first_url + second_url)

    get first_url
    assert_response :success
    assert_select 'input[type="search"][value="Private sample title"]'
    assert_select 'select#tag option[selected][value="demo"]'
    get second_url
    assert_response :success
    assert_select 'input[type="search"][value="nonexistent title"]'
    assert_select "h2", text: "No matching secrets"
  end
end
