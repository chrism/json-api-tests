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
end
