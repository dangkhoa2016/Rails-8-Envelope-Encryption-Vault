class VaultRevealsController < ApplicationController
  def create
    item = Current.user.vault_items.find(params[:vault_item_id])

    if Rails.configuration.x.security.reauth_on_reveal && !Current.session&.recently_reauthenticated?
      session[:return_to_after_reauthentication] = vault_item_path(item)
      render partial: "vault_items/reauth_required", locals: { item: item }, status: :unauthorized
      return
    end

    @payload = Vault::RevealItem.call(user: Current.user, item: item)
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    render partial: "vault_items/revealed", locals: { payload: @payload }
  rescue Crypto::Error, ArgumentError
    render plain: "This secret could not be decrypted.", status: :unprocessable_entity
  end
end
