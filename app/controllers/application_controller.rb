class ApplicationController < ActionController::Base
  include Authentication
  protect_from_forgery with: :exception
  allow_browser versions: :modern if respond_to?(:allow_browser)

  before_action :capture_request_context
  before_action :require_mfa_enrollment_if_configured
  after_action :protect_sensitive_responses

  private

  def capture_request_context
    Current.request_id = request.request_id
    Current.audit_request_details = Audit::RequestDetails.capture(request)
  end

  def require_mfa_enrollment_if_configured
    return unless Current.user
    return unless Rails.configuration.x.security.require_mfa
    return if Current.user.mfa_enabled?
    return if controller_path == "settings/mfa" || controller_name.in?([ "sessions", "reauthentications" ])

    redirect_to settings_mfa_path, alert: "Multi-factor authentication is required for this vault."
  end

  def protect_sensitive_responses
    # Dynamic application pages are never intentionally browser/proxy cached.
    # Static fingerprinted assets are served separately with long-lived cache headers.
    response.headers["Cache-Control"] ||= "no-store"
    response.headers["Pragma"] ||= "no-cache"
  end
end
