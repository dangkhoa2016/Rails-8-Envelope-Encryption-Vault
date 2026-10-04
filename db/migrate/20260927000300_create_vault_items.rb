class CreateVaultItems < ActiveRecord::Migration[8.1]
  def change
    create_table :vault_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.boolean :favorite, null: false, default: false
      t.datetime :archived_at
      t.timestamps
    end
    add_index :vault_items, %i[user_id kind]
    add_index :vault_items, %i[user_id archived_at]
    add_index :vault_items, %i[user_id favorite]
  end
end
