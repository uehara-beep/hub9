class AddSecretToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :secret_pin_digest, :string
    add_column :users, :secret_unlocked_at, :datetime
  end
end
