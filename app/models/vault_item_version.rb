class VaultItemVersion < ApplicationRecord
  belongs_to :vault_item
  belongs_to :created_by_user, class_name: "User"

  validates :version_number, numericality: { only_integer: true, greater_than: 0 }
  validates :envelope_version, :aad_version, numericality: { only_integer: true, greater_than: 0 }
  validates :cipher_suite, :payload_format, :key_provider, :kek_id, presence: true
  validates :ciphertext, :nonce, :authentication_tag, :wrapped_dek, presence: true

  before_update :prevent_payload_mutation

  def to_envelope
    Crypto::Envelope.new(
      envelope_version: envelope_version,
      payload_format: payload_format,
      cipher_suite: cipher_suite,
      ciphertext: ciphertext,
      nonce: nonce,
      authentication_tag: authentication_tag,
      key_provider: key_provider,
      kek_id: kek_id,
      wrapped_dek: wrapped_dek,
      aad_version: aad_version
    )
  end

  private

  def prevent_payload_mutation
    allowed = %w[wrapped_dek kek_id]
    forbidden = changes_to_save.keys - allowed
    throw(:abort) if forbidden.any?
  end
end
