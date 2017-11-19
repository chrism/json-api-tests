class CreateSchedules < ActiveRecord::Migration[5.1]
  def change
    create_table :schedules do |t|
      t.string :name
      t.integer :current_position, default: 0

      t.timestamps
    end
  end
end
