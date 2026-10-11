class VaultItemVersionsController < ApplicationController
  before_action :set_item
  before_action :require_recent_reauthentication, only: :restore

  def index
    @versions = @item.versions.order(version_number: :desc)
  end

  def restore
    version = @item.versions.find(params[:id])
    Vault::RestoreVersion.call(user: Current.user, item: @item, version: version)
    redirect_to vault_item_path(@item), notice: "Version restored as a new encrypted version."
  rescue Crypto::Error, ArgumentError
    redirect_to vault_item_versions_path(@item), alert: "That version could not be restored."
  end

  private

  def set_item
    @item = Current.user.vault_items.find(params[:vault_item_id])
  end
end
