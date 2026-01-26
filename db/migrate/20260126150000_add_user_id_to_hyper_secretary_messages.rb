class AddUserIdToHyperSecretaryMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :hyper_secretary_messages, :user, foreign_key: true
  end
end
