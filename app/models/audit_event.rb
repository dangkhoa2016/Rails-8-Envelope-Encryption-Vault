class AuditEvent < ApplicationRecord
  SENSITIVE_KEY = /(passw|secret|token|api[_-]?key|private[_-]?key|plaintext|env_text|wrapped_dek|ciphertext|authentication_tag|nonce|otp|recovery_code|\Avalue\z)/i

  belongs_to :user, optional: true
  belongs_to :vault_item, optional: true
  validates :action, presence: true
  validate :metadata_must_not_contain_sensitive_fields
  before_validation :capture_request_id, on: :create

  def readonly?
    persisted?
  end

  private

  def capture_request_id
    self.request_id ||= Current.request_id if defined?(Current)
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
