class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.references :vault_item, type: :uuid, foreign_key: true
      t.string :action, null: false
      t.string :request_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_events, %i[user_id created_at]
    add_index :audit_events, %i[vault_item_id created_at]
  end
end
