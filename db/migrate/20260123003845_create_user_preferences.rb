class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: true, foreign_key: true
      t.integer :strictness, default: 1

      t.timestamps
    end
  end
end
