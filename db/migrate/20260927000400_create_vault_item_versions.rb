class CreateVaultItemVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :vault_item_versions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :vault_item, null: false, type: :uuid, foreign_key: true
      t.integer :version_number, null: false
      t.integer :envelope_version, null: false, default: 1
      t.string :payload_format, null: false, default: "json.v1"
      t.string :cipher_suite, null: false, default: "AES-256-GCM"
      t.binary :ciphertext, null: false
      t.binary :nonce, null: false
      t.binary :authentication_tag, null: false
      t.string :key_provider, null: false
      t.string :kek_id, null: false
      t.binary :wrapped_dek, null: false
      t.integer :aad_version, null: false, default: 1
      t.references :created_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.datetime :created_at, null: false
    end

    add_index :vault_item_versions, %i[vault_item_id version_number], unique: true, name: "index_vault_versions_item_number"
    add_check_constraint :vault_item_versions, "octet_length(nonce) = 12", name: "vault_versions_nonce_12_bytes"
    add_check_constraint :vault_item_versions, "octet_length(authentication_tag) = 16", name: "vault_versions_tag_16_bytes"
    add_check_constraint :vault_item_versions, "octet_length(ciphertext) > 0", name: "vault_versions_ciphertext_nonempty"
    add_check_constraint :vault_item_versions, "octet_length(wrapped_dek) > 0", name: "vault_versions_wrapped_dek_nonempty"
    add_check_constraint :vault_item_versions, "version_number > 0", name: "vault_versions_positive_version"
  end
end
