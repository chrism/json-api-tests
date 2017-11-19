require 'rails_helper'

RSpec.describe "Schedules", type: :request do
  describe "GET /api/v1/schedules" do
    it "has correct status and content type" do
      get "/api/v1/schedules"
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/vnd.api+json")
    end

    it "has empty body array by default" do
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(0).at_path("data")
    end

    it "includes a schedule model when added" do
      Schedule.create(name: "Test")
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(1).at_path("data")
      expect(json).to have_json_path("data/0/id")
      attributes = %({
        "name": "Test",
        "current-position": 0
      })
      expect(response.body).to be_json_eql(attributes).at_path("data/0/attributes")
    end

    it "includes two schedule models when added" do
      Schedule.create(name: "Test")
      Schedule.create(name: "Test 2")
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(2).at_path("data")
      expect(json).to have_json_path("data/1/id")
      attributes = %({
        "name": "Test 2",
        "current-position": 0
      })
      expect(json).to be_json_eql(attributes).at_path("data/1/attributes")
    end
  end

  describe "GET /api/v1/schedules/id" do
    it "should use the slug as the id" do
      Schedule.create(name: "Test With Spaces")
      get "/api/v1/schedules/test-with-spaces"
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/vnd.api+json")
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to be_json_eql(%("test-with-spaces")).at_path("data/id")
      expect(json).to be_json_eql(response.request.url.to_json).at_path("data/links/self")
    end

    it "includes the scheduled tracks links" do
      schedule = Schedule.create(name: "Test")
      ScheduledTrack.create(position: 1, schedule: schedule)
      ScheduledTrack.create(position: 2, schedule: schedule)
      get "/api/v1/schedules/test"
      json = response.body
      url_prepend = response.request.url
      expect(json).to have_json_path("data/relationships")
      expect(json).to be_json_eql(%("#{url_prepend}/relationships/scheduled-tracks")).at_path("data/relationships/scheduled-tracks/links/self")
      expect(json).to be_json_eql(%("#{url_prepend}/scheduled-tracks")).at_path("data/relationships/scheduled-tracks/links/related")
    end
  end
end
