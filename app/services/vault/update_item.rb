require "securerandom"

module Vault
  class UpdateItem
    def self.call(user:, item:, payload:, key_provider: KeyProviders::Registry.fetch, action: "vault_item.updated")
      raise ActiveRecord::RecordNotFound unless item.user_id == user.id

      VaultItem.transaction do
        item.lock!
        version_id = SecureRandom.uuid
        next_number = item.versions.maximum(:version_number).to_i + 1
        context = { user_id: user.id, vault_item_id: item.id, vault_item_version_id: version_id }
        plaintext = Crypto::PayloadSerializer.dump(payload)
        envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: plaintext, context: context, key_provider: key_provider)
        version = item.versions.create!(id: version_id, version_number: next_number, created_by_user: user, **envelope.to_h)
        item.update!(current_version: version)
        AuditEvent.create!(user: user, vault_item: item, action: action, metadata: { version_number: next_number })
        version
      ensure
        plaintext = nil
      end
    end
  end
end
