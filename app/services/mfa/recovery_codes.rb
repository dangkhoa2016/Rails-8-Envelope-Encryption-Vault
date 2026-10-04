require "securerandom"

module Mfa
  class RecoveryCodes
    COUNT = 10

    def self.regenerate!(user:)
      raw_codes = Array.new(COUNT) { format_code(SecureRandom.hex(8).upcase) }
      MfaRecoveryCode.transaction do
        user.mfa_recovery_codes.delete_all
        now = Time.current
        raw_codes.each do |raw|
          normalized = raw.delete("-")
          user.mfa_recovery_codes.create!(code_digest: BCrypt::Password.create(normalized), created_at: now)
        end
      end
      raw_codes
    end

    def self.consume!(user:, candidate:)
      normalized = candidate.to_s.delete("-").upcase
      return false if normalized.empty?

      user.mfa_recovery_codes.unused.find_each do |record|
        next unless record.matches?(normalized)

        consumed = false
        record.with_lock do
          record.reload
          if record.used_at.nil? && record.matches?(normalized)
            record.update!(used_at: Time.current)
            consumed = true
          end
        end
        return true if consumed
      end
      false
    end

    def self.format_code(value)
      value.scan(/.{1,4}/).join("-")
    end
    private_class_method :format_code
  end
end
