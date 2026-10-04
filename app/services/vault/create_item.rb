require "securerandom"

module Vault
  class CreateItem
    def self.call(user:, kind:, payload:, key_provider: KeyProviders::Registry.fetch)
      VaultItem.transaction do
        item = user.vault_items.create!(id: SecureRandom.uuid, kind: kind)
        version_id = SecureRandom.uuid
        plaintext = Crypto::PayloadSerializer.dump(payload)
        context = { user_id: user.id, vault_item_id: item.id, vault_item_version_id: version_id }
        envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: plaintext, context: context, key_provider: key_provider)

        version = item.versions.create!(
          id: version_id,
          version_number: 1,
          created_by_user: user,
          **envelope.to_h
        )
        item.update!(current_version: version)
        AuditEvent.create!(user: user, vault_item: item, action: "vault_item.created", metadata: { kind: item.kind })
        item
      ensure
        plaintext = nil
      end
    end
  end
end
