class MfaRecoveryCode < ApplicationRecord
  belongs_to :user

  scope :unused, -> { where(used_at: nil) }

  def matches?(candidate)
    BCrypt::Password.new(code_digest).is_password?(candidate.to_s.delete("-").upcase)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def consume!
    update!(used_at: Time.current)
  end
end
