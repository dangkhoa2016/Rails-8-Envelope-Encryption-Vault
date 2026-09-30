module Settings
  class MfaController < ApplicationController
    before_action :require_recent_reauthentication, only: %i[new create destroy regenerate_recovery_codes]

    def show
      @enabled = Current.user.mfa_enabled?
      @remaining_codes = Current.user.mfa_recovery_codes.unused.count
    end

    def new
      if Current.user.mfa_enabled?
        redirect_to settings_mfa_path, notice: "MFA is already enabled." and return
      end

      setting = Current.user.mfa_setting
      if setting.nil? || setting.setup_expired?
        setting&.destroy!
        setting = Mfa::SecretStore.begin_setup!(user: Current.user)
      end
      prepare_setup_view(setting)
    rescue Crypto::Error, ArgumentError
      Current.user.mfa_setting&.destroy!
      redirect_to settings_mfa_path, alert: "Unable to begin MFA enrollment."
    end

    def create
      setting = Current.user.mfa_setting or raise ActiveRecord::RecordNotFound
      raise ArgumentError, "MFA setup is already enabled" if setting.enabled?
      raise ArgumentError, "MFA setup expired" if setting.setup_expired?

      secret = Mfa::SecretStore.secret_for(user: Current.user, allow_pending: true)
      counter = Security::Totp.matching_counter(token: params[:token], secret: secret)
      unless counter
        prepare_setup_view(setting, secret: secret)
        flash.now[:alert] = "Invalid TOTP code."
        render :new, status: :unprocessable_entity
        return
      end

      user = Current.user
      User.transaction do
        Mfa::SecretStore.confirm!(user: user, counter: counter)
        @recovery_codes = Mfa::RecoveryCodes.regenerate!(user: user)
      end
      user.sessions.where.not(id: Current.session.id).update_all(revoked_at: Time.current)
      rotate_authenticated_session!(user)
      AuditEvent.create!(user: user, action: "user.mfa_enabled", metadata: { other_sessions_revoked: true, session_rotated: true })
      render :recovery_codes
    rescue Crypto::Error, ArgumentError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
      if Current.user&.mfa_enabled?
        redirect_to settings_mfa_path, alert: "MFA is enabled, but enrollment finalization encountered an error. Verify recovery codes before signing out."
      else
        Current.user&.mfa_setting&.destroy!
        redirect_to new_settings_mfa_path, alert: "MFA enrollment expired or could not be verified. Start again."
      end
    ensure
      secret = nil
    end

    def destroy
      unless valid_current_token?(params[:token])
        redirect_to settings_mfa_path, alert: "Valid TOTP or recovery code required." and return
      end

      Current.user.mfa_setting&.destroy!
      Current.user.mfa_recovery_codes.delete_all
      Current.user.sessions.where.not(id: Current.session.id).update_all(revoked_at: Time.current)
      user = Current.user
      rotate_authenticated_session!(user)
      AuditEvent.create!(user: user, action: "user.mfa_disabled", metadata: { other_sessions_revoked: true, session_rotated: true })
      redirect_to settings_mfa_path, notice: "MFA disabled."
    end

    def regenerate_recovery_codes
      unless valid_current_token?(params[:token])
        redirect_to settings_mfa_path, alert: "Valid TOTP or recovery code required." and return
      end
      @recovery_codes = Mfa::RecoveryCodes.regenerate!(user: Current.user)
      AuditEvent.create!(user: Current.user, action: "user.mfa_recovery_codes_regenerated", metadata: {})
      render :recovery_codes
    end

    private

    def valid_current_token?(token)
      Mfa::Verifier.verify(user: Current.user, candidate: token)
    end

    def prepare_setup_view(setting, secret: nil)
      @secret = secret || Mfa::SecretStore.secret_for(user: Current.user, allow_pending: true)
      @uri = Security::Totp.provisioning_uri(secret: @secret, email: Current.user.email_address)
      @setup_expires_at = setting.setup_expires_at
    end
  end
end
