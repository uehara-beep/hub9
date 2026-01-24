class AddPurgeToVaultEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :vault_entries, :purge_on, :date
    add_column :vault_entries, :purge_warned_at, :datetime
    add_column :vault_entries, :deleted_at, :datetime
  end
end
