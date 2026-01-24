class AddConversationToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :conversation, null: true, foreign_key: true
  end
end
