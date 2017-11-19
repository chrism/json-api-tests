class Schedule < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :scheduled_tracks
end
