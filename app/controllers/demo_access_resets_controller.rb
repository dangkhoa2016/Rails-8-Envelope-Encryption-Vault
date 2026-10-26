# Only the disposable public showcase can reset its single shared identity.
# The endpoint remains registered in private deployments but always returns 404.
class DemoAccessResetsController < ApplicationController
  allow_unauthenticated_access only: :create

  def create
    head :not_found and return unless Demo::AccessReset.enabled?

    Demo::AccessReset.call
    cookies.delete(:session_id)
    reset_session
    Current.session = nil

    redirect_to new_session_path,
      status: :see_other,
      notice: "Demo password and MFA have been reset. Sign in with the displayed test credentials. Existing sessions were signed out."
  rescue Demo::AccessReset::Forbidden, ActiveRecord::RecordNotFound
    head :not_found
  end
end
