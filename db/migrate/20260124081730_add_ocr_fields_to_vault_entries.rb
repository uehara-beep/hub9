class AddOcrFieldsToVaultEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :vault_entries, :parsed_json, :jsonb
    add_column :vault_entries, :hidden, :boolean
    add_column :vault_entries, :expires_at, :datetime
  end
end
