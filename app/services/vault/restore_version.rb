module Vault
  class RestoreVersion
    def self.call(user:, item:, version:, key_provider: KeyProviders::Registry.fetch)
      raise ActiveRecord::RecordNotFound unless item.user_id == user.id && version.vault_item_id == item.id
      context = { user_id: user.id, vault_item_id: item.id, vault_item_version_id: version.id }
      plaintext = Crypto::EnvelopeEncryptor.decrypt(envelope: version.to_envelope, context: context, key_provider: key_provider)
      payload = Crypto::PayloadSerializer.load(plaintext)
      Vault::UpdateItem.call(user: user, item: item, payload: payload, key_provider: key_provider, action: "vault_item.restored")
    end
  end
end
