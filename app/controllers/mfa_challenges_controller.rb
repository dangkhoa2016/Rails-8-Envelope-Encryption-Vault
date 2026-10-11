class MfaChallengesController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @pending_user = require_pending_user!
    nil unless @pending_user
  end

  def create
    user = require_pending_user!
    return unless user
    token = params[:token].to_s.strip
    valid = Mfa::Verifier.verify(user: user, candidate: token)

    if valid
      destination = session.delete(:pending_mfa_return_to)
      session.delete(:pending_mfa_user_id)
      session.delete(:pending_mfa_authenticated_at)
      start_new_session_for(user)
      AuditEvent.create!(user: user, action: "user.login_succeeded", metadata: { mfa: true })
      redirect_to destination.presence || root_path
    else
      AuditEvent.create!(user: user, action: "user.mfa_failed", metadata: {})
      redirect_to new_mfa_challenge_path, alert: "Invalid authentication code."
    end
  rescue Crypto::Error, ArgumentError
    reset_session
    redirect_to new_session_path, alert: "MFA verification is unavailable."
  end

  private

  def require_pending_user!
    user_id = session[:pending_mfa_user_id]
    at = session[:pending_mfa_authenticated_at].to_i
    if user_id.blank? || at.zero? || Time.at(at) < Time.current - Rails.configuration.x.security.pending_mfa_timeout
      reset_session
      redirect_to new_session_path, alert: "Your sign-in challenge expired."
      return nil
    end
    User.find(user_id)
  rescue ActiveRecord::RecordNotFound
    reset_session
    redirect_to new_session_path, alert: "Your sign-in challenge is no longer valid."
    nil
  end
end
