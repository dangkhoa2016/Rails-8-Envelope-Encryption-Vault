class VaultExportsController < ApplicationController
  before_action :require_recent_reauthentication

  def create
    item = Current.user.vault_items.find(params[:vault_item_id])
    raise ActiveRecord::RecordNotFound unless item.kind == "environment"
    payload = Vault::RevealItem.call(user: Current.user, item: item, audit: false)
    body = Vault::EnvParser.dump(payload.fetch("entries"))
    AuditEvent.create!(user: Current.user, vault_item: item, action: "vault_item.exported", metadata: { format: "dotenv" })
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    send_data body, filename: "vault-#{item.id}.env", type: "text/plain", disposition: "attachment"
  rescue Crypto::Error, ArgumentError
    render plain: "This environment secret could not be decrypted.", status: :unprocessable_entity
  end
end
