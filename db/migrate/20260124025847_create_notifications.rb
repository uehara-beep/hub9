class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.string :kind
      t.string :title
      t.text :body
      t.datetime :read_at

      t.timestamps
    end
  end
end
