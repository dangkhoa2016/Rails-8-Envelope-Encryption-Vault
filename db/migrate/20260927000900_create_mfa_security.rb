class CreateMfaSecurity < ActiveRecord::Migration[8.1]
  def change
    create_table :mfa_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
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
      # Null while enrollment is pending. The encrypted TOTP seed is kept
      # server-side instead of in the browser's cookie-backed Rails session.
      t.datetime :enabled_at
      t.datetime :setup_expires_at, null: false
      t.timestamps
    end

    add_check_constraint :mfa_settings, "octet_length(nonce) = 12", name: "mfa_settings_nonce_12_bytes"
    add_check_constraint :mfa_settings, "octet_length(authentication_tag) = 16", name: "mfa_settings_tag_16_bytes"
    add_check_constraint :mfa_settings, "octet_length(ciphertext) > 0", name: "mfa_settings_ciphertext_nonempty"
    add_check_constraint :mfa_settings, "octet_length(wrapped_dek) > 0", name: "mfa_settings_wrapped_dek_nonempty"

    create_table :mfa_recovery_codes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :code_digest, null: false
      t.datetime :used_at
      t.datetime :created_at, null: false
    end

    add_index :mfa_recovery_codes, [ :user_id, :used_at ]
  end
end
