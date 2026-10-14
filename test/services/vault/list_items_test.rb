require "test_helper"

class VaultListItemsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "list-items@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
  end

  test "filters metadata before decrypting and searches encrypted titles in memory" do
    create_item("Alpha login", kind: "login")
    create_item("Beta login", kind: "login")
    archived = create_item("Alpha archived", kind: "login")
    archived.update!(archived_at: Time.current)
    create_item("Alpha environment", kind: "environment")

    revealed_before = AuditEvent.where(user: @user, action: "vault_item.revealed").count
    result = Vault::ListItems.call(user: @user, q: "alpha", kind: "login", status: "active")

    assert_equal [ "Alpha login" ], result.summaries.map(&:last)
    assert_equal 1, result.total
    assert_equal revealed_before, AuditEvent.where(user: @user, action: "vault_item.revealed").count
  end

  test "never includes another users matching encrypted title" do
    other_user = User.create!(
      email_address: "other-list-items@example.test",
      password: "long-password-1234",
      password_confirmation: "long-password-1234"
    )
    create_item("Shared-looking title")
    Vault::CreateItem.call(
      user: other_user,
      kind: "login",
      payload: {
        "schema" => "vault.login.v1",
        "title" => "Shared-looking title",
        "username" => "",
        "password" => "",
        "url" => "",
        "notes" => "",
        "tags" => []
      }
    )

    result = Vault::ListItems.call(user: @user, q: "shared-looking", status: "all")

    assert_equal 1, result.total
    assert result.summaries.all? { |item, _| item.user_id == @user.id }
  end

  test "paginates only after title search" do
    4.times { |index| create_item("Match #{index}") }
    create_item("Different")

    first = Vault::ListItems.call(user: @user, q: "match", status: "all", page: 1, per_page: 2)
    second = Vault::ListItems.call(user: @user, q: "match", status: "all", page: 2, per_page: 2)

    assert_equal 4, first.total
    assert_equal 2, first.total_pages
    assert_equal 2, first.summaries.length
    assert_equal 2, second.summaries.length
  end


  test "uses a practical default page size to expose paging in the demo" do
    7.times { |index| create_item("Sample login #{index}") }

    first = Vault::ListItems.call(user: @user, status: "all")
    second = Vault::ListItems.call(user: @user, status: "all", page: 2)

    assert_equal 6, first.per_page
    assert_equal 7, first.total
    assert_equal 2, first.total_pages
    assert_equal 6, first.summaries.size
    assert_equal 1, second.summaries.size
  end

  test "filters favorites in metadata and tags in decrypted application memory" do
    favorite = create_item("Production database", tags: %w[production billing])
    favorite.update!(favorite: true)
    create_item("Staging database", tags: %w[staging billing])
    create_item("Production login", tags: %w[production auth])

    result = Vault::ListItems.call(user: @user, favorite: true, tag: "PRODUCTION", status: "all")

    assert_equal [ "Production database" ], result.summaries.map(&:last)
    assert_equal [ "billing", "production" ], result.available_tags
    assert_equal %w[production billing], result.tags_by_item_id.fetch(favorite.id)
  end

  private

  def create_item(title, kind: "login", tags: [])
    payload =
      if kind == "environment"
        {
          "schema" => "vault.environment.v1",
          "title" => title,
          "environment" => "test",
          "entries" => [],
          "notes" => "",
          "tags" => tags
        }
      else
        {
          "schema" => "vault.#{kind}.v1",
          "title" => title,
          "username" => "",
          "password" => "",
          "url" => "",
          "notes" => "",
          "tags" => tags
        }
      end

    Vault::CreateItem.call(user: @user, kind: kind, payload: payload)
  end
end
