require 'rails_helper'

# t.integer  "event_id"
# t.integer  "split_id"

RSpec.describe EventSplit, type: :model do
  it "should be valid with an event_id and a split_id" do
    event_split = EventSplit.create!(event_id: 1, split_id: 1)

    expect(EventSplit.all.count).to(equal(1))
    expect(event_split).to be_valid
  end

  it "should be invalid without an event_id" do
    event_split = EventSplit.new(event_id: nil, split_id: 1)
    expect(event_split).not_to be_valid
    expect(event_split.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    event_split = EventSplit.new(event_id: 1, split_id: nil)
    expect(event_split).not_to be_valid
    expect(event_split.errors[:split_id]).to include("can't be blank")
  end

end
