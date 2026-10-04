require "securerandom"

module Mfa
  class SecretStore
    SETUP_TTL = 10.minutes

    # Programmatic enable path used by tests/import tooling. Interactive web
    # enrollment uses begin_setup! + confirm! so the seed is never stored in
    # the cookie-backed Rails session.
    def self.enable!(user:, secret:, last_totp_counter: nil, key_provider: KeyProviders::Registry.fetch)
      MfaSetting.transaction do
        user.mfa_setting&.destroy!
        setting = build_encrypted_setting(
          user: user,
          secret: secret,
          enabled_at: Time.current,
          setup_expires_at: Time.current,
          last_totp_counter: last_totp_counter,
          key_provider: key_provider
        )
        setting.save!
        setting
      end
    end

    def self.begin_setup!(user:, key_provider: KeyProviders::Registry.fetch)
      raise ArgumentError, "MFA is already enabled" if user.mfa_enabled?

      MfaSetting.transaction do
        user.mfa_setting&.destroy!
        secret = Security::Totp.generate_secret
        setting = build_encrypted_setting(
          user: user,
          secret: secret,
          setup_expires_at: Time.current + SETUP_TTL,
          key_provider: key_provider
        )
        setting.save!
        setting
      ensure
        secret = nil
      end
    end

    def self.confirm!(user:, counter:)
      setting = user.mfa_setting or raise ActiveRecord::RecordNotFound
      raise ArgumentError, "MFA setup is already enabled" if setting.enabled?
      raise ArgumentError, "MFA setup expired" if setting.setup_expired?

      setting.update_columns(
        enabled_at: Time.current,
        setup_expires_at: Time.current,
        last_totp_counter: counter,
        updated_at: Time.current
      )
      setting
    end

    def self.secret_for(user:, allow_pending: false, key_provider: KeyProviders::Registry.fetch)
      setting = user.mfa_setting or raise ActiveRecord::RecordNotFound
      unless setting.enabled?
        raise ArgumentError, "MFA setup is not enabled" unless allow_pending
        raise ArgumentError, "MFA setup expired" if setting.setup_expired?
      end

      plaintext = Crypto::EnvelopeEncryptor.decrypt(
        envelope: setting.to_envelope,
        context: setting.encryption_context,
        key_provider: key_provider
      )
      Crypto::PayloadSerializer.load(plaintext).fetch("secret")
    ensure
      plaintext = nil
    end

    def self.build_encrypted_setting(user:, secret:, setup_expires_at:, key_provider:, enabled_at: nil, last_totp_counter: nil)
      setting = user.build_mfa_setting(
        id: SecureRandom.uuid,
        enabled_at: enabled_at,
        setup_expires_at: setup_expires_at,
        last_totp_counter: last_totp_counter
      )
      plaintext = Crypto::PayloadSerializer.dump("schema" => "mfa.totp.v1", "secret" => secret)
      envelope = Crypto::EnvelopeEncryptor.encrypt(
        plaintext: plaintext,
        context: setting.encryption_context,
        key_provider: key_provider
      )
      setting.assign_attributes(envelope.to_h)
      setting
    ensure
      plaintext = nil
    end
    private_class_method :build_encrypted_setting
  end
end
