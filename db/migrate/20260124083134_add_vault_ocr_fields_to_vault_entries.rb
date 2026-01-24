class AddVaultOcrFieldsToVaultEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :vault_entries, :ocr_status, :string
    add_column :vault_entries, :ocr_error, :text
    add_column :vault_entries, :ocr_target, :string
  end
end
