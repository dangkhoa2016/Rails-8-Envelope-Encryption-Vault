class AddTotpReplayProtection < ActiveRecord::Migration[8.1]
  def change
    add_column :mfa_settings, :last_totp_counter, :bigint
  end
end
