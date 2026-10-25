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

  test "defaults to active while archived and all remain explicit choices" do
    active = create_item("Active reference")
    archived = create_item("Archived reference")
    archived.update!(archived_at: Time.current)

    default = Vault::ListItems.call(user: @user)
    archived_only = Vault::ListItems.call(user: @user, status: "archived")
    all = Vault::ListItems.call(user: @user, status: "all")

    assert_equal [ active.id ], default.summaries.map { |item, _| item.id }
    assert_equal [ archived.id ], archived_only.summaries.map { |item, _| item.id }
    assert_equal [ active.id, archived.id ].sort, all.summaries.map { |item, _| item.id }.sort
    assert_equal 1, default.total
    assert_equal 2, all.total
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


  test "unfiltered listing only decrypts requested page and preserves global count" do
    13.times { |index| create_item("Listing page #{index}", tags: [ "list" ]) }

    seen = []
    original_reveal = Vault::RevealItem.method(:call)
    singleton = Vault::RevealItem.singleton_class
    singleton.define_method(:call) do |**args|
      seen << args.fetch(:item).id
      original_reveal.call(**args)
    end

    begin
      first = Vault::ListItems.call(user: @user, page: 1)
      assert_equal 13, first.total
      assert_equal 6, first.summaries.length
      assert_equal 6, seen.length

      seen.clear
      last = Vault::ListItems.call(user: @user, page: 3)
      assert_equal 13, last.total
      assert_equal 1, last.summaries.length
      assert_equal 1, seen.length
    ensure
      singleton.define_method(:call, original_reveal)
    end
  end

  test "title and tag searches include matching items beyond the former 250 limit" do
    250.times { |i| create_item("ordinary #{i}", tags: [ "ordinary" ]) }
    target = create_item("Needle beyond limit", tags: [ "deeply-hidden" ])
    # Put the target outside the newest/favorite-first ordering window.
    target.update!(updated_at: Time.current - 1.year)

    by_title = Vault::ListItems.call(user: @user, q: "needle", status: "all")
    by_tag = Vault::ListItems.call(user: @user, tag: "deeply-hidden", status: "all")
    all = Vault::ListItems.call(user: @user, status: "all", page: 42)

    assert_equal [ target.id ], by_title.summaries.map { |item, _| item.id }
    assert_equal [ target.id ], by_tag.summaries.map { |item, _| item.id }
    assert_equal 251, all.total
    assert_equal 42, all.total_pages
    assert_equal 5, all.summaries.size
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
