class CreateChargeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :charge_entries do |t|
      t.integer :direction        # 0: in(受取), 1: out(支払)
      t.integer :amount_yen
      t.string :category
      t.string :counterparty
      t.text :note
      t.date :occurred_on

      t.timestamps
    end
  end
end
