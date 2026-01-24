class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :mode

      t.timestamps
    end
    add_index :conversations, :mode
  end
end
