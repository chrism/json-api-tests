class Schedule < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :scheduled_tracks
  has_many :forthcoming_tracks, -> { where(state: ['playing','next','queued']) }, class_name: "ScheduledTrack"

  validates_presence_of :name
end
