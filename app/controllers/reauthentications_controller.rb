class ReauthenticationsController < ApplicationController
  def new; end

  def create
    user = Current.user
    password_ok = user.authenticate(params[:password].to_s)
    # Never consume a one-time recovery code when the password is wrong.
    mfa_ok = password_ok && (!user.mfa_enabled? || valid_mfa?(user, params[:token]))

    if password_ok && mfa_ok
      destination = session.delete(:return_to_after_reauthentication).presence || root_path
      rotate_authenticated_session!(user)
      AuditEvent.create!(user: user, action: "user.reauthenticated", metadata: { session_rotated: true })
      redirect_to destination
    else
      AuditEvent.create!(user: user, action: "user.reauthentication_failed", metadata: {})
      redirect_to new_reauthentication_path, alert: "Verification failed."
    end
  end

  private

  def valid_mfa?(user, token)
    Mfa::Verifier.verify(user: user, candidate: token)
  end
end
