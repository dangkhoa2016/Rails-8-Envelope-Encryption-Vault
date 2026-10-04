class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :vault_items, dependent: :destroy
  has_many :audit_events, dependent: :nullify
  has_one :mfa_setting, dependent: :destroy
  has_many :mfa_recovery_codes, dependent: :destroy

  before_validation { self.email_address = email_address.to_s.strip.downcase }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 14, maximum: 72 }, allow_nil: true
  validate :password_fits_bcrypt_limit

  def mfa_enabled?
    mfa_setting&.enabled_at.present?
  end

  private

  def password_fits_bcrypt_limit
    return if password.nil? || password.bytesize <= 72

    errors.add(:password, "must be at most 72 bytes for bcrypt")
  end
end
