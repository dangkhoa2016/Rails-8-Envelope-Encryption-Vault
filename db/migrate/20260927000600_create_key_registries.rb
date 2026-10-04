class CreateKeyRegistries < ActiveRecord::Migration[8.1]
  def change
    create_table :key_registries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :provider, null: false
      t.string :kek_id, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :activated_at
      t.datetime :retired_at
      t.timestamps
    end
    add_index :key_registries, %i[provider kek_id], unique: true
  end
end
