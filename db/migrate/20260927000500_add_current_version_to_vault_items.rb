class AddCurrentVersionToVaultItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :vault_items, :current_version, type: :uuid, foreign_key: { to_table: :vault_item_versions }
  end
end
