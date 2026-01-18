class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :role
      t.text :content
      t.integer :visibility
      t.jsonb :metadata

      t.timestamps
    end
  end
end
