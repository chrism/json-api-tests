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

  describe "GET /api/v1/schedules/id?include=forthcoming-tracks" do
    it "includes forthcoming tracks relationship and data" do
      schedule = Schedule.create(name: "Test")
      ScheduledTrack.create(position: 1, state: "played", schedule: schedule)
      ScheduledTrack.create(position: 2, state: "playing", schedule: schedule)
      ScheduledTrack.create(position: 3, schedule: schedule)
      get "/api/v1/schedules/test?include=forthcoming-tracks"
      json = response.body
      expect(json).to have_json_path("data/relationships/forthcoming-tracks")
      expect(json).to have_json_size(2).at_path("included")
    end
  end

  describe "POST /api/v1/schedules" do
    it "returns error if there is no content-type" do
      post "/api/v1/schedules"
      error_message = %({
        "errors": [
          {
            "title": "Unsupported media type",
            "detail": "All requests that create or update must use the 'application/vnd.api+json' Content-Type. This request specified 'application/x-www-form-urlencoded'.",
            "code": "415",
            "status": "415"
          }
        ]
      })
      expect(response).to have_http_status(415)
      expect(response.body).to be_json_eql(error_message)
    end

    it "returns error if there is no name attribute" do
      post_data = {
        data: {
          type: "schedules",
          attributes: {}
        }
      }.to_json
      post "/api/v1/schedules", params: post_data, headers: { 'Content-Type': 'application/vnd.api+json' }
      error_message = %({
        "errors": [
          {
            "title": "can't be blank",
            "detail": "name - can't be blank",
            "code": "100",
            "source": {
              "pointer": "/data/attributes/name"
            },
            "status": "422"
          }
        ]
      })
      expect(response).to have_http_status(422)
      expect(response.body).to be_json_eql(error_message)
    end

    it "creates a new schedule if name is included" do
      post_data = {
        data: {
          type: "schedules",
          attributes: {
            name: "Test 3"
          }
        }
      }.to_json
      post "/api/v1/schedules", params: post_data, headers: { 'Content-Type': 'application/vnd.api+json' }
      expect(response).to have_http_status(201)
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to be_json_eql(%("test-3")).at_path("data/id")
    end
  end
end
