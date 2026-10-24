class AuditEvent < ApplicationRecord
  SENSITIVE_KEY = /(passw|secret|token|api[_-]?key|private[_-]?key|plaintext|env_text|wrapped_dek|ciphertext|authentication_tag|nonce|otp|recovery_code|\Avalue\z)/i

  belongs_to :user, optional: true
  belongs_to :vault_item, optional: true
  validates :action, presence: true
  validate :metadata_must_not_contain_sensitive_fields
  before_validation :capture_request_id, on: :create
  before_validation :capture_authentication_context, on: :create

  AUTHENTICATION_ACTIONS = %w[
    user.login_succeeded user.login_failed user.logout user.reauthenticated
    user.reauthentication_failed user.mfa_failed
  ].freeze

  def readonly?
    persisted?
  end

  private

  def capture_request_id
    self.request_id ||= Current.request_id if defined?(Current)
  end

  def capture_authentication_context
    return unless AUTHENTICATION_ACTIONS.include?(action)
    return unless defined?(Current) && Current.audit_request_details.present?

    # Only the allowlisted request snapshot may set request-origin fields.
    self.metadata = metadata.to_h.stringify_keys.merge(Current.audit_request_details)
  end

  def metadata_must_not_contain_sensitive_fields
    offending = sensitive_metadata_key(metadata)
    errors.add(:metadata, "contains forbidden sensitive field #{offending}") if offending
  end

  def sensitive_metadata_key(value, path = [])
    case value
    when Hash
      value.each do |key, nested|
        key_string = key.to_s
        return (path + [ key_string ]).join(".") if key_string.match?(SENSITIVE_KEY)
        found = sensitive_metadata_key(nested, path + [ key_string ])
        return found if found
      end
    when Array
      value.each_with_index do |nested, index|
        found = sensitive_metadata_key(nested, path + [ index.to_s ])
        return found if found
      end
    end
    nil
  end
end
