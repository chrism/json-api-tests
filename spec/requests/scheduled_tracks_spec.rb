require 'rails_helper'

RSpec.describe "ScheduledTracks", type: :request do
  describe "GET /scheduled-tracks/:id" do
    it "should return the position and default state" do
      schedule_track = ScheduledTrack.create(position: 1, schedule: Schedule.create(name: 'Test'))
      get "/api/v1/scheduled-tracks/#{schedule_track.id}"
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/vnd.api+json")
      attributes = %({
        "position": 1,
        "state": "queued"
      })
      expect(response.body).to be_json_eql(attributes).at_path("data/attributes")
    end
  end
end
