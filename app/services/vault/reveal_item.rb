module Vault
  class RevealItem
    def self.call(user:, item:, key_provider: KeyProviders::Registry.fetch, audit: true)
      raise ActiveRecord::RecordNotFound unless item.user_id == user.id
      version = item.current_version or raise ActiveRecord::RecordNotFound
      context = { user_id: user.id, vault_item_id: item.id, vault_item_version_id: version.id }
      plaintext = Crypto::EnvelopeEncryptor.decrypt(envelope: version.to_envelope, context: context, key_provider: key_provider)
      payload = Crypto::PayloadSerializer.load(plaintext)
      AuditEvent.create!(user: user, vault_item: item, action: "vault_item.revealed", metadata: {}) if audit
      payload
    ensure
      plaintext = nil
    end
  end
end
