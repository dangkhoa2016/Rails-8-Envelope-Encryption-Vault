class VaultItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update archive unarchive favorite unfavorite]
  before_action :require_recent_reauthentication, only: %i[edit update]

  def index
    load_index
  end

  def search
    load_index
    render :index
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

  def load_index
    result = Vault::ListItems.call(
      user: Current.user,
      q: params[:q],
      kind: params[:kind],
      status: params[:status],
      favorite: params[:favorite],
      tag: params[:tag],
      page: params[:page]
    )
    @summaries = result.summaries
    @page = result.page
    @total = result.total
    @total_pages = result.total_pages
    @query = params[:q].to_s
    @kind_filter = params[:kind].to_s.presence_in(VaultItem::KINDS)
    @status_filter = params[:status].to_s.presence_in(%w[active archived all]) || "all"
    @favorite_filter = ActiveModel::Type::Boolean.new.cast(params[:favorite])
    @tag_filter = params[:tag].to_s.strip.first(80)
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
