module Settings
  class SecurityController < ApplicationController
    before_action :require_recent_reauthentication, only: :update

    def show; end

    def update
      user = Current.user
      unless user.authenticate(params[:current_password].to_s)
        redirect_to settings_security_path, alert: "Current password is incorrect." and return
      end

      user.update!(password: params.require(:password), password_confirmation: params.require(:password_confirmation))
      user.sessions.where.not(id: Current.session.id).update_all(revoked_at: Time.current)
      rotate_authenticated_session!(user)
      AuditEvent.create!(user: user, action: "user.password_changed", metadata: { other_sessions_revoked: true, session_rotated: true })
      redirect_to settings_security_path, notice: "Password changed; all previous sessions were revoked."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to settings_security_path, alert: e.record.errors.full_messages.to_sentence
    end
  end
end
