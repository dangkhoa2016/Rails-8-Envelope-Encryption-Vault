require "uri"

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    return Current.session if Current.session&.active?

    record = find_session_by_cookie
    unless record&.active?
      record&.revoke!
      cookies.delete(:session_id)
      Current.session = nil
      return nil
    end

    record.touch_activity!
    Current.session = record
  end

  def find_session_by_cookie
    id = cookies.signed[:session_id]
    Session.find_by(id: id) if id.present?
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.fullpath if request.get? || request.head?
    redirect_to new_session_path
  end

  def start_new_session_for(user)
    reset_session
    now = Time.current
    record = user.sessions.create!(
      user_agent: request.user_agent.to_s.first(255),
      ip_address: request.remote_ip,
      last_seen_at: now,
      absolute_expires_at: now + Rails.configuration.x.security.session_absolute_timeout,
      reauthenticated_at: now
    )
    install_session_cookie(record)
    record
  end

  # Rotate the server-side session identifier after a sensitive authentication
  # boundary (reauthentication, password change, MFA enable/disable). This
  # limits the useful lifetime of a captured pre-boundary session identifier.
  def rotate_authenticated_session!(user = Current.user)
    Current.session&.revoke!
    start_new_session_for(user)
  end

  def install_session_cookie(record)
    Current.session = record
    cookies.signed[:session_id] = {
      value: record.id,
      expires: record.absolute_expires_at,
      httponly: true,
      same_site: :strict,
      secure: Rails.env.production? && ENV.fetch("FORCE_SSL", "true") == "true"
    }
  end

  def terminate_session
    Current.session&.revoke!
    cookies.delete(:session_id)
    reset_session
    Current.session = nil
  end

  def require_recent_reauthentication
    return if Current.session&.recently_reauthenticated?

    session[:return_to_after_reauthentication] = safe_reauthentication_return_path
    redirect_to new_reauthentication_path, alert: "Please confirm your identity, then retry the sensitive action."
  end

  def safe_reauthentication_return_path
    return request.fullpath if request.get? || request.head?
    return root_path if request.referer.blank?

    uri = URI.parse(request.referer)
    expected_scheme = request.protocol.delete_suffix("://")
    return root_path unless uri.host == request.host && uri.scheme == expected_scheme && uri.port == request.port

    uri.request_uri.presence || root_path
  rescue URI::InvalidURIError
    root_path
  end
end
