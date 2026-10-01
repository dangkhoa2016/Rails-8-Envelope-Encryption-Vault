module Mfa
  class Verifier
    def self.verify(user:, candidate:, at: Time.current)
      setting = user.mfa_setting or return false
      secret = Mfa::SecretStore.secret_for(user: user)
      counter = Security::Totp.matching_counter(token: candidate, secret: secret, at: at)

      if counter
        accepted = false
        setting.with_lock do
          setting.reload
          if setting.last_totp_counter.nil? || counter > setting.last_totp_counter
            setting.update_columns(last_totp_counter: counter, updated_at: Time.current)
            accepted = true
          end
        end
        return accepted
      end

      Mfa::RecoveryCodes.consume!(user: user, candidate: candidate)
    rescue Crypto::Error, ArgumentError, ActiveRecord::RecordNotFound
      false
    ensure
      secret = nil
    end
  end
end
