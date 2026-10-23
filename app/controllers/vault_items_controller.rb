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
    elsif params[:page].present?
      # Backward compatibility for older page-only links, without storing a
      # duplicate copy of large plaintext search strings in the session cookie.
      latest = session[:vault_current_filter_token]
      filters = (session[:vault_filter_snapshots] || {})[latest]
      @filter_token = latest if filters
      filters ||= session[:vault_listing_filters] || {}
    else
      session.delete(:vault_listing_filters)
      session.delete(:vault_current_filter_token)
      filters = {}
    end
    load_index(filters)
  end

  def search
    # Submitting a search never copies private q/tag filters into the URL.
    filters = {
      "q" => params[:q].to_s.strip.first(200),
      "kind" => params[:kind].to_s.presence_in(VaultItem::KINDS),
      "status" => params[:status].to_s.presence_in(%w[active archived all]) || "all",
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
    redirect_to vault_items_path, notice: "Item archived."
  end

  def unarchive
    @item.update!(archived_at: nil)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: "vault_item.unarchived", metadata: {})
    redirect_to vault_items_path, notice: "Item restored to your vault."
  end

  def favorite
    @item.update!(favorite: true)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: "vault_item.favorited", metadata: {})
    redirect_to vault_items_path, notice: "Added to favorites."
  end

  def unfavorite
    @item.update!(favorite: false)
    AuditEvent.create!(user: Current.user, vault_item: @item, action: "vault_item.unfavorited", metadata: {})
    redirect_to vault_items_path, notice: "Removed from favorites."
  end

  private

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

  def load_index(filters)
    safe_query = listing_query_params(filters, @filter_token)
    result = Vault::ListItems.call(
      user: Current.user,
      q: filters["q"],
      kind: filters["kind"],
      status: filters["status"],
      favorite: filters["favorite"],
      tag: filters["tag"],
      page: params[:page],
      # Pagy links are always GET index URLs with known-safe parameters,
      # regardless of whether the listing was rendered by POST or GET.
      request: { base_url: request.base_url, path: vault_items_path, params: safe_query.stringify_keys }
    )
    @summaries = result.summaries
    @pagy = result.pagy
    @page = result.page
    @total = result.total
    @total_pages = result.total_pages
    @vault_listing_url = vault_items_path(**safe_query.merge(page: @page))
    @query = filters["q"].to_s
    @kind_filter = filters["kind"].to_s.presence_in(VaultItem::KINDS)
    @status_filter = filters["status"].to_s.presence_in(%w[active archived all]) || "all"
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
