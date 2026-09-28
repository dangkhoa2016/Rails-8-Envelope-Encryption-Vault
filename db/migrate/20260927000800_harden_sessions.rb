class HardenSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :last_seen_at, :datetime
    add_column :sessions, :absolute_expires_at, :datetime
    add_column :sessions, :revoked_at, :datetime

    # Old v0.1.0 sessions did not have enforceable expiry metadata. Revoke them
    # and populate deterministic values before making the new fields NOT NULL.
    execute <<~SQL.squish
      UPDATE sessions
      SET last_seen_at = COALESCE(updated_at, created_at, CURRENT_TIMESTAMP),
          absolute_expires_at = CURRENT_TIMESTAMP,
          revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP)
    SQL

    change_column_null :sessions, :last_seen_at, false
    change_column_null :sessions, :absolute_expires_at, false

    add_index :sessions, :absolute_expires_at
    add_index :sessions, [ :user_id, :revoked_at ]
  end

  def down
    remove_index :sessions, [ :user_id, :revoked_at ]
    remove_index :sessions, :absolute_expires_at
    remove_column :sessions, :revoked_at
    remove_column :sessions, :absolute_expires_at
    remove_column :sessions, :last_seen_at
  end
end
