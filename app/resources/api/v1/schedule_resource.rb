class Api::V1::ScheduleResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :current_position

  has_many "forthcoming_tracks", class_name: 'ScheduledTracks', relation_name: :forthcoming_tracks
  has_many "scheduled_tracks"
end
