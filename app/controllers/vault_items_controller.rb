class VaultItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update archive unarchive favorite unfavorite]
  before_action :require_recent_reauthentication, only: %i[edit update]

  # Filter tokens identify session-local snapshots; decrypted titles and tag names
  # never become URL query parameters or server-side shared cache keys.
  MAX_FILTER_SNAPSHOTS = 4
  FILTER_TOKEN_PATTERN = /\A[0-9a-f]{32}\z/

  def index
    token = params[:filter].to_s
    if token.present?
      snapshots = session[:vault_filter_snapshots] || {}
      filters = snapshots[token] if FILTER_TOKEN_PATTERN.match?(token)
      @filter_token = token if filters
      filters ||= {}
    elsif params[:page].present? && params[:sort].blank?
      # Backward compatibility for older page-only links, without storing a
      # duplicate copy of large plaintext search strings in the session cookie.
      latest = session[:vault_current_filter_token]
      filters = (session[:vault_filter_snapshots] || {})[latest]
      @filter_token = latest if filters
      filters ||= session[:vault_listing_filters] || {}
    else
      session.delete(:vault_listing_filters)
      session.delete(:vault_current_filter_token)
      # State is safe for a direct GET link. Search text and tags stay in
      # opaque session-scoped filter snapshots and never enter URLs.
      filters = { "status" => params[:status].to_s.presence_in(%w[active archived all]) || "active" }
    end
    load_index(filters)
  end

  def search
    # Submitting a search never copies private q/tag filters into the URL.
    filters = {
      "q" => params[:q].to_s.strip.first(200),
      "kind" => params[:kind].to_s.presence_in(VaultItem::KINDS),
      "status" => params[:status].to_s.presence_in(%w[active archived all]) || "active",
      "tag" => params[:tag].to_s.strip.first(80),
      "favorite" => ActiveModel::Type::Boolean.new.cast(params[:favorite]) ? "1" : "0"
    }
    session.delete(:vault_listing_filters)
    snapshots = (session[:vault_filter_snapshots] || {}).dup
    @filter_token = SecureRandom.hex(16)
    snapshots[@filter_token] = filters
    snapshots = snapshots.to_a.last(MAX_FILTER_SNAPSHOTS).to_h
    # Rails' encrypted cookie session has a strict size limit. Preserve the
    # newest filter while evicting older snapshots if search terms are large.
    snapshots.shift while snapshots.size > 1 && snapshots.to_json.bytesize > 1_200
    session[:vault_filter_snapshots] = snapshots
    session[:vault_current_filter_token] = @filter_token

    respond_to do |format|
      format.turbo_stream do
        load_index(filters)
        @async_search = true
        render turbo_stream: turbo_stream.replace("vault_listing", partial: "vault_items/listing")
      end
      # Forms without JavaScript still reach the same safe GET listing URL.
      format.html do
        redirect_to vault_items_path(**listing_query_params(filters, @filter_token).merge(page: 1)), status: :see_other
      end
    end
  end

  def new
    @kind = params[:kind].presence_in(VaultItem::KINDS) || "login"
  end

  def create
    item = Vault::CreateItem.call(user: Current.user, kind: requested_kind, payload: payload_from_params)
    redirect_to vault_item_path(item), notice: "Encrypted secret created."
  rescue ArgumentError => e
    redirect_to new_vault_item_path(kind: requested_kind), alert: e.message
  end

  def show; end

  def edit
    @payload = Vault::RevealItem.call(user: Current.user, item: @item, audit: false)
  rescue Crypto::Error, ArgumentError
    redirect_to vault_item_path(@item), alert: "This secret could not be decrypted."
  end

  def update
    existing_payload = Vault::RevealItem.call(user: Current.user, item: @item, audit: false)
    Vault::UpdateItem.call(
      user: Current.user,
      item: @item,
      payload: payload_from_params(existing_payload: existing_payload)
    )
    redirect_to vault_item_path(@item), notice: "New encrypted version created."
  rescue ArgumentError => e
    redirect_to edit_vault_item_path(@item), alert: e.message
  ensure
    existing_payload = nil
  end

  def archive
    @item.update!(archived_at: Time.current)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: "vault_item.archived", metadata: {})
    redirect_to vault_items_path, notice: "Item archived. Find it in Archived; encrypted data and versions remain."
  end

  def unarchive
    @item.update!(archived_at: nil)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: "vault_item.unarchived", metadata: {})
    redirect_to vault_items_path, notice: "Item restored to Active vault items."
  end

  def favorite
    change_favorite(favorite: true, action: "vault_item.favorited", notice: "Added to favorites.")
  end

  def unfavorite
    change_favorite(favorite: false, action: "vault_item.unfavorited", notice: "Removed from favorites.")
  end

  private

  def change_favorite(favorite:, action:, notice:)
    @item.update!(favorite: favorite)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: action, metadata: {})

    detail = params[:source] == "detail"
    listing = params[:source] == "listing"
    context = listing_context if listing

    respond_to do |format|
      format.turbo_stream do
        if detail
          render turbo_stream: [
            turbo_stream.replace(
              "vault_favorite_control",
              partial: "vault_items/favorite_control",
              locals: { item: @item, updated: true }
            ),
            turbo_stream.update(
              "toast_notifications",
              partial: "shared/toast",
              locals: { message: notice, kind: :notice }
            )
          ]
        elsif listing
          if context[:filters]["favorite"] == "1" && !favorite
            # The item no longer matches the Favorites-only filter. Refresh the
            # listing fragment (not the document), preserving the opaque filter
            # and requested page unless the final page becomes empty.
            @filter_token = context[:token]
            load_index(context[:filters], requested_page: context[:page],
              requested_sort: context[:sort], requested_direction: context[:direction])
            @async_search = @page != context[:page]
            updated_listing = turbo_stream.replace("vault_listing", partial: "vault_items/listing")
          else
            updated_listing = turbo_stream.replace(
              helpers.dom_id(@item, :listing_favorite_control),
              partial: "vault_items/listing_favorite_control",
              locals: { item: @item, page: context[:page], filter: context[:token],
                        status: context[:status], sort: context[:sort],
                        direction: context[:direction], updated: true }
            )
          end
          render turbo_stream: [
            updated_listing,
            turbo_stream.update(
              "toast_notifications",
              partial: "shared/toast",
              locals: { message: notice, kind: :notice }
            )
          ]
        else
          redirect_to vault_items_path, status: :see_other, notice: notice
        end
      end
      format.html do
        destination = if detail
          vault_item_path(@item)
        elsif listing
          safe_listing_path(context)
        else
          vault_items_path
        end
        redirect_to destination, status: :see_other, notice: notice
      end
    end
  end

  def listing_context
    # Never trust a user-supplied redirect URL or reveal private search terms.
    raw_page = params[:page].to_s
    page = raw_page.match?(/\A[1-9][0-9]{0,5}\z/) ? raw_page.to_i : 1
    snapshots = session[:vault_filter_snapshots] || {}
    token = params[:filter].to_s
    token = nil unless FILTER_TOKEN_PATTERN.match?(token) && snapshots.key?(token)
    status = params[:status].to_s.presence_in(%w[active archived all]) || "active"
    filters = token ? snapshots.fetch(token) : { "status" => status }
    sort = params[:sort].to_s.presence_in(Vault::ListItems::SORT_KEYS) || Vault::ListItems::DEFAULT_SORT
    direction = params[:direction].to_s.presence_in(Vault::ListItems::SORT_DIRECTIONS) || Vault::ListItems::DEFAULT_DIRECTION
    { page: page, token: token, status: status, filters: filters, sort: sort, direction: direction }
  end

  def safe_listing_path(context)
    query = { page: context[:page], sort: context[:sort], direction: context[:direction] }
    query[:filter] = context[:token] if context[:token]
    query[:status] = context[:status] if context[:status] != "active" && !context[:token]
    vault_items_path(**query)
  end

  def listing_query_params(filters, token)
    return {} unless token

    # Type/state/favorite are non-secret UI classifications. q/tag stay private.
    {}.tap do |query|
      query[:filter] = token
      query[:kind] = filters["kind"] if filters["kind"].present?
      query[:status] = filters["status"] if filters["status"].present? && filters["status"] != "all"
      query[:favorite] = "1" if filters["favorite"] == "1"
    end
  end

  def load_index(filters, requested_page: params[:page], requested_sort: params[:sort],
                 requested_direction: params[:direction])
    @sort = requested_sort.to_s.presence_in(Vault::ListItems::SORT_KEYS) || Vault::ListItems::DEFAULT_SORT
    @direction = requested_direction.to_s.presence_in(Vault::ListItems::SORT_DIRECTIONS) || Vault::ListItems::DEFAULT_DIRECTION
    safe_query = listing_query_params(filters, @filter_token)
    if @filter_token.blank? && filters["status"].to_s.in?(%w[archived all])
      safe_query[:status] = filters["status"]
    end
    @sort_base_params = safe_query
    sort_query = safe_query.merge(sort: @sort, direction: @direction)
    result = Vault::ListItems.call(
      user: Current.user,
      q: filters["q"],
      kind: filters["kind"],
      status: filters["status"],
      favorite: filters["favorite"],
      tag: filters["tag"],
      page: requested_page,
      sort: @sort,
      direction: @direction,
      # Pagy links are always GET index URLs with known-safe parameters,
      # regardless of whether the listing was rendered by POST or GET.
      request: { base_url: request.base_url, path: vault_items_path, params: sort_query.stringify_keys }
    )
    @summaries = result.summaries
    @pagy = result.pagy
    @page = result.page
    @total = result.total
    @total_pages = result.total_pages
    @vault_listing_url = vault_items_path(**sort_query.merge(page: @page))
    @query = filters["q"].to_s
    @kind_filter = filters["kind"].to_s.presence_in(VaultItem::KINDS)
    @status_filter = filters["status"].to_s.presence_in(%w[active archived all]) || "active"
    @favorite_filter = ActiveModel::Type::Boolean.new.cast(filters["favorite"])
    @tag_filter = filters["tag"].to_s.strip.first(80)
    @tags_by_item_id = result.tags_by_item_id
    @available_tags = result.available_tags
    @vault_empty = Current.user.vault_items.none?
  end

  def requested_kind
    params.fetch(:kind, @item&.kind || "login").presence_in(VaultItem::KINDS) || "login"
  end

  def payload_from_params(existing_payload: nil)
    base = {
      "schema" => "vault.#{requested_kind}.v1",
      "title" => params.require(:title),
      "notes" => params[:notes].to_s,
      "tags" => normalize_tags(params[:tags], existing_payload:)
    }

    case requested_kind
    when "environment"
      base.merge(
        "environment" => params[:environment_name].to_s,
        "entries" => Vault::EnvParser.parse(params[:env_text].to_s)
      )
    when "secure_note"
      base.merge("body" => params[:body].to_s)
    when "database"
      base.merge(
        "host" => params[:host].to_s,
        "port" => params[:port].to_s,
        "database_name" => params[:database_name].to_s,
        "username" => params[:username].to_s,
        "password" => preserved_secret(existing_payload)
      )
    when "ssh"
      base.merge(
        "host" => params[:host].to_s,
        "port" => params[:port].presence || "22",
        "username" => params[:username].to_s,
        "password" => preserved_secret(existing_payload)
      )
    when "api_key"
      base.merge(
        "username" => params[:username].to_s,
        "password" => preserved_secret(existing_payload),
        "url" => params[:url].to_s
      )
    else
      base.merge(
        "username" => params[:username].to_s,
        "password" => preserved_secret(existing_payload),
        "url" => params[:url].to_s
      )
    end
  end

  def preserved_secret(existing_payload)
    submitted = params[:secret_value].to_s
    submitted.empty? ? existing_payload&.fetch("password", "").to_s : submitted
  end

  def normalize_tags(raw_tags, existing_payload:)
    return existing_payload.fetch("tags", []) if raw_tags.nil? && existing_payload

    raw_tags.to_s.split(",").map(&:strip).reject(&:blank?).uniq.first(12)
  end

  def set_item
    @item = Current.user.vault_items.find(params[:id])
  end
end
