# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_27_001300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "audit_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "vault_item_id"
    t.string "action", null: false
    t.string "request_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["user_id", "created_at"], name: "index_audit_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
    t.index ["vault_item_id", "created_at"], name: "index_audit_events_on_vault_item_id_and_created_at"
    t.index ["vault_item_id"], name: "index_audit_events_on_vault_item_id"
  end

  create_table "key_registries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", null: false
    t.string "kek_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "activated_at"
    t.datetime "retired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "kek_id"], name: "index_key_registries_on_provider_and_kek_id", unique: true
  end

  create_table "mfa_recovery_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "code_digest", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.index ["user_id", "used_at"], name: "index_mfa_recovery_codes_on_user_id_and_used_at"
    t.index ["user_id"], name: "index_mfa_recovery_codes_on_user_id"
  end

  create_table "mfa_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "envelope_version", default: 1, null: false
    t.string "payload_format", default: "json.v1", null: false
    t.string "cipher_suite", default: "AES-256-GCM", null: false
    t.binary "ciphertext", null: false
    t.binary "nonce", null: false
    t.binary "authentication_tag", null: false
    t.string "key_provider", null: false
    t.string "kek_id", null: false
    t.binary "wrapped_dek", null: false
    t.integer "aad_version", default: 1, null: false
    t.datetime "enabled_at"
    t.datetime "setup_expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "last_totp_counter"
    t.index ["user_id"], name: "index_mfa_settings_on_user_id", unique: true
    t.check_constraint "octet_length(authentication_tag) = 16", name: "mfa_settings_tag_16_bytes"
    t.check_constraint "octet_length(ciphertext) > 0", name: "mfa_settings_ciphertext_nonempty"
    t.check_constraint "octet_length(nonce) = 12", name: "mfa_settings_nonce_12_bytes"
    t.check_constraint "octet_length(wrapped_dek) > 0", name: "mfa_settings_wrapped_dek_nonempty"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "reauthenticated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "absolute_expires_at", null: false
    t.datetime "revoked_at"
    t.index ["absolute_expires_at"], name: "index_sessions_on_absolute_expires_at"
    t.index ["user_id", "revoked_at"], name: "index_sessions_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
  end

  create_table "vault_item_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "vault_item_id", null: false
    t.integer "version_number", null: false
    t.integer "envelope_version", default: 1, null: false
    t.string "payload_format", default: "json.v1", null: false
    t.string "cipher_suite", default: "AES-256-GCM", null: false
    t.binary "ciphertext", null: false
    t.binary "nonce", null: false
    t.binary "authentication_tag", null: false
    t.string "key_provider", null: false
    t.string "kek_id", null: false
    t.binary "wrapped_dek", null: false
    t.integer "aad_version", default: 1, null: false
    t.uuid "created_by_user_id", null: false
    t.datetime "created_at", null: false
    t.index ["created_by_user_id"], name: "index_vault_item_versions_on_created_by_user_id"
    t.index ["vault_item_id", "version_number"], name: "index_vault_versions_item_number", unique: true
    t.index ["vault_item_id"], name: "index_vault_item_versions_on_vault_item_id"
    t.check_constraint "aad_version > 0", name: "vault_versions_positive_aad_version"
    t.check_constraint "envelope_version > 0", name: "vault_versions_positive_envelope_version"
    t.check_constraint "octet_length(authentication_tag) = 16", name: "vault_versions_tag_16_bytes"
    t.check_constraint "octet_length(ciphertext) > 0", name: "vault_versions_ciphertext_nonempty"
    t.check_constraint "octet_length(nonce) = 12", name: "vault_versions_nonce_12_bytes"
    t.check_constraint "octet_length(wrapped_dek) > 0", name: "vault_versions_wrapped_dek_nonempty"
    t.check_constraint "version_number > 0", name: "vault_versions_positive_version"
  end

  create_table "vault_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "kind", null: false
    t.boolean "favorite", default: false, null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "current_version_id"
    t.index ["current_version_id"], name: "index_vault_items_on_current_version_id"
    t.index ["user_id", "archived_at"], name: "index_vault_items_on_user_id_and_archived_at"
    t.index ["user_id", "favorite"], name: "index_vault_items_on_user_id_and_favorite"
    t.index ["user_id", "kind"], name: "index_vault_items_on_user_id_and_kind"
    t.index ["user_id"], name: "index_vault_items_on_user_id"
  end

  add_foreign_key "audit_events", "users"
  add_foreign_key "audit_events", "vault_items"
  add_foreign_key "mfa_recovery_codes", "users"
  add_foreign_key "mfa_settings", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "vault_item_versions", "users", column: "created_by_user_id"
  add_foreign_key "vault_item_versions", "vault_items"
  add_foreign_key "vault_items", "users"
  add_foreign_key "vault_items", "vault_item_versions", column: "current_version_id", on_delete: :nullify
end
