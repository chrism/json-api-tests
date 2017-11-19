class AddSlugToSchedules < ActiveRecord::Migration[5.1]
  def change
    add_column :schedules, :slug, :string
    add_index :schedules, :slug, unique: true
  end
end
