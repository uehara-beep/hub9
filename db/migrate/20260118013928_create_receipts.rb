class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :visibility
      t.integer :bucket
      t.string :note
      t.text :ocr_raw_text
      t.jsonb :extracted_data

      t.timestamps
    end
  end
end
