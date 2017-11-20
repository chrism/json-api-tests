class Api::V1::ScheduledTrackResource < JSONAPI::Resource
  caching
  
  attributes :position, :state
end
