class CreateDailyContexts < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_contexts do |t|
      t.references :user, null: true, foreign_key: true
      t.date :date
      t.text :morning_focus
      t.text :risks
      t.text :next_actions

      t.timestamps
    end
  end
end
