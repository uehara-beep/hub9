class CreateVaultEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :vault_entries do |t|
      t.date :occurred_on
      t.integer :kind
      t.integer :amount_yen
      t.string :tag
      t.text :memo

      t.timestamps
    end
  end
end
