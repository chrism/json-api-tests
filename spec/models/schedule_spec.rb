require 'rails_helper'

RSpec.describe Schedule, type: :model do
  it "is valid with a name" do
    schedule = Schedule.new(
      name: "Orange Gardens Radio"
    )
    expect(schedule).to be_valid
  end

  it "has a current_position of 0" do
    schedule = Schedule.new(
      name: "Orange Gardens Radio"
    )
    expect(schedule.current_position).to be_zero
  end
end
