class AddVaultVersionIntegrityConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :vault_item_versions, "envelope_version > 0", name: "vault_versions_positive_envelope_version"
    add_check_constraint :vault_item_versions, "aad_version > 0", name: "vault_versions_positive_aad_version"
  end
end
