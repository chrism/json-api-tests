class CreateScheduledTracks < ActiveRecord::Migration[5.1]
  def change
    create_table :scheduled_tracks do |t|
      t.integer :position
      t.string :state, default: 'queued'
      t.belongs_to :schedule, foreign_key: true

      t.timestamps
    end
  end
end
