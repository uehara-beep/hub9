class CreateHyperSecretaryMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :hyper_secretary_messages do |t|
      t.string :role
      t.text :content
      t.string :kind
      t.integer :direction
      t.integer :amount_yen
      t.string :category
      t.string :counterparty
      t.jsonb :extracted
      t.integer :charge_entry_id

      t.timestamps
    end

    add_index :hyper_secretary_messages, :charge_entry_id
  end
end
