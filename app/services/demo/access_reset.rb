module Demo
  # Recovery for one disposable, shared public-demo identity only.
  # Never use for private vaults, staging, or real user accounts.
  class AccessReset
    class Forbidden < StandardError; end

    def self.enabled?
      ENV["DEMO_MODE"] == "true" &&
        ENV["SHOW_PUBLIC_DEMO_CREDENTIALS"] == "true" &&
        ENV["PUBLIC_DEMO_RESET_ENABLED"] == "true" &&
        ENV["ALLOW_SIGNUPS"] == "false" &&
        ENV["REQUIRE_MFA"] == "false" &&
        ENV["DEMO_EMAIL"] == Demo::FixtureBuilder::DEMO_EMAIL
    end

    def self.call
      raise Forbidden, "Public demo reset is disabled" unless enabled?

      password = ENV.fetch("DEMO_PASSWORD")
      if !password.length.between?(14, 72) || password.bytesize > 72
        raise Forbidden, "Invalid demo password configuration"
      end

      User.transaction do
        user = User.lock.find_by!(email_address: Demo::FixtureBuilder::DEMO_EMAIL)
        revoked_count = user.sessions.where(revoked_at: nil).count

        user.update!(password: password, password_confirmation: password)
        user.mfa_setting&.destroy!
        user.mfa_recovery_codes.delete_all
        user.sessions.where(revoked_at: nil).update_all(revoked_at: Time.current)
        AuditEvent.create!(
          user: user, action: "user.public_demo_access_reset",
          metadata: { sessions_revoked: revoked_count, mfa_cleared: true }
        )
      end
      true
    ensure
      password = nil
    end
  end
end
