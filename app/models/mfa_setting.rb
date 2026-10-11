class MfaSetting < ApplicationRecord
  belongs_to :user

  validates :ciphertext, :nonce, :authentication_tag, :wrapped_dek, :key_provider, :kek_id, presence: true
  validates :setup_expires_at, presence: true
  before_update :prevent_secret_payload_mutation

  def enabled?
    enabled_at.present?
  end

  def setup_expired?(at = Time.current)
    !enabled? && setup_expires_at <= at
  end

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

  def encryption_context
    {
      user_id: user_id,
      vault_item_id: "mfa-setting:#{user_id}",
      vault_item_version_id: id
    }
  end

  private

  def prevent_secret_payload_mutation
    # Ciphertext/nonce/tag/AAD metadata are immutable. Key rotation is allowed
    # to change only the wrapped DEK + KEK id; enrollment/replay state may move
    # independently without rewriting the encrypted TOTP seed.
    allowed = %w[wrapped_dek kek_id enabled_at setup_expires_at last_totp_counter updated_at]
    throw(:abort) if (changes_to_save.keys - allowed).any?
  end
end
