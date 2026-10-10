class HardenCurrentVersionForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :vault_items, column: :current_version_id
    add_foreign_key :vault_items, :vault_item_versions, column: :current_version_id, on_delete: :nullify
  end
end
