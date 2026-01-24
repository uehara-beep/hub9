class AddCategoryToVaultEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :vault_entries, :category, :string
  end
end
