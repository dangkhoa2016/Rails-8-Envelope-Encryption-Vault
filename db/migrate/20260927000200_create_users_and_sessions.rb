class CreateUsersAndSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address"

    create_table :sessions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.datetime :reauthenticated_at
      t.timestamps
    end
  end
end
