class Api::V1::ScheduleResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :current_position
end