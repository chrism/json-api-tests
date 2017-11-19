require 'rails_helper'

RSpec.describe ScheduledTrack, type: :model do
  let!(:schedule) { Schedule.create(name: 'test') }

  it "is valid with a position" do
    scheduled_track = ScheduledTrack.new(
      position: 1,
      schedule: schedule
    )
    expect(scheduled_track).to be_valid
  end

  it "has a state of queued" do
    scheduled_track = ScheduledTrack.new(
      position: 1,
      schedule: schedule
    )
    expect(scheduled_track.state).to eq "queued"
  end
end
