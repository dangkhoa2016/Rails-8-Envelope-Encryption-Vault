class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new; end

  def create
    email = params[:email_address].to_s.strip.downcase
    if (user = User.authenticate_by(email_address: email, password: params[:password]))
      if user.mfa_enabled?
        destination = session.delete(:return_to_after_authenticating)
        reset_session
        session[:pending_mfa_user_id] = user.id
        session[:pending_mfa_authenticated_at] = Time.current.to_i
        session[:pending_mfa_return_to] = destination if destination.present?
        redirect_to new_mfa_challenge_path
      else
        complete_login(user)
      end
    else
      AuditEvent.create!(action: "user.login_failed", metadata: {})
      redirect_to new_session_path, alert: "Email or password is incorrect."
    end
  end

  def destroy
    AuditEvent.create!(user: Current.user, action: "user.logout", metadata: {}) if Current.user
    terminate_session
    redirect_to new_session_path
  end

  private

  def complete_login(user)
    destination = session.delete(:return_to_after_authenticating)
    start_new_session_for(user)
    AuditEvent.create!(user: user, action: "user.login_succeeded", metadata: {})
    redirect_to destination.presence || root_path
  end
end
