require "rails_helper"

# t.integer  "course_id"
# t.integer  "location_id"
# t.string   "name"
# t.integer  "distance_from_start"
# t.integer  "sub_order"
# t.integer  "vert_gain_from_start"
# t.integer  "vert_loss_from_start"
# t.integer  "kind"
# t.string   "description"

RSpec.describe Split, kind: :model do
  it "should be valid when created with a course_id, a name, a distance_from_start, and a kind" do
    course = Course.create!(name: 'Test Course')
    Split.create!(course_id: course.id,
                  location_id: nil,
                  name: 'Hopeless Outbound In',
                  distance_from_start: 50000,
                  kind: 2)

    expect(Split.all.count).to(equal(1))
    expect(Split.first.course_id).to eq(course.id)
    expect(Split.first.name).to eq('Hopeless Outbound In')
    expect(Split.first.distance_from_start).to eq(50000)
    expect(Split.first.sub_order).to eq(0)    # default value
    expect(Split.first.waypoint?).to eq(true)
  end

  it "should be invalid without a course_id" do
    split = Split.new(course_id: nil, location_id: 1, name: 'Test Location', distance_from_start: 2000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:course_id]).to include("can't be blank")
  end

  it "should be invalid without a name" do
    split = Split.new(course_id: 1, location_id: 1, name: nil, distance_from_start: 2000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:name]).to include("can't be blank")
  end

  it "should be invalid without a distance_from_start" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Test', distance_from_start: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("can't be blank")
  end

  it "should be invalid without a sub_order" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Test', distance_from_start: 3000, sub_order: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:sub_order]).to include("can't be blank")
  end

  it "should be invalid without a kind" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Test', distance_from_start: 6000, kind: nil)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("can't be blank")
  end

  it "should not allow duplicate names within the same course" do
    Split.create!(course_id: 1, location_id: 1, name: 'Wanderlust In', distance_from_start: 7000, kind: 2)
    split = Split.new(course_id: 1, location_id: 1, name: 'Wanderlust In', distance_from_start: 8000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:name]).to include("has already been taken")
  end

  it "should allow duplicate names among different courses" do
    Split.create!(course_id: 1, location_id: 1, name: 'Wanderlust In', distance_from_start: 7000, kind: 2)
    split = Split.new(course_id: 2, location_id: 1, name: 'Wanderlust In', distance_from_start: 8000, kind: 2)
    expect(split).to be_valid
  end

  it "should not permit multiple splits of the same distance without different sub_orders" do
    Split.create!(course_id: 1, location_id: 1, name: 'Aid Station In', distance_from_start: 7000, sub_order: 0, kind: 2)
    split = Split.new(course_id: 1, location_id: 1, name: 'Aid Station Out', distance_from_start: 7000, sub_order: 0, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include ("has already been taken")
  end

  it "should permit multiple splits of the same distance with different sub_orders" do
    Split.create!(course_id: 1, location_id: 1, name: 'Aid Station In', distance_from_start: 7000, sub_order: 0, kind: 2)
    split = Split.new(course_id: 1, location_id: 1, name: 'Aid Station Out', distance_from_start: 7000, sub_order: 1, kind: 2)
    expect(split).to be_valid
  end

  it "should not allow more than one start split within the same course" do
    Split.create!(course_id: 1, location_id: 1, name: 'Starting Point', distance_from_start: 0, sub_order: 0, kind: 0)
    split = Split.new(course_id: 1, location_id: 1, name: 'Beginning Point', distance_from_start: 0, sub_order: 1, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("only one start split permitted on a course")
  end

  it "should not allow more than one finish split within the same course" do
    Split.create!(course_id: 1, location_id: 1, name: 'Finish Point', distance_from_start: 5000, sub_order: 0, kind: 1)
    split = Split.new(course_id: 1, location_id: 1, name: 'Ending Point', distance_from_start: 5000, sub_order: 1, kind: 1)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("only one finish split permitted on a course")
  end

  it "should allow multiple waypoint splits within the same course" do
    Split.create!(course_id: 1, location_id: 1, name: 'Aid1 In', distance_from_start: 9000, sub_order: 0, kind: 2)
    split1 = Split.new(course_id: 1, location_id: 1, name: 'Aid1 Out', distance_from_start: 9000, sub_order: 1, kind: 2)
    split2 =Split.new(course_id: 1, location_id: 2, name: 'Aid2 In', distance_from_start: 18000, sub_order: 0, kind: 2)
    split3 = Split.new(course_id: 1, location_id: 2, name: 'Aid2 Out', distance_from_start: 18000, sub_order: 1, kind: 2)
    expect(split1).to be_valid
    expect(split2).to be_valid
    expect(split3).to be_valid
  end

  it "should require start splits to have distance_from_start: 0, vert_gain_from_start: 0, and vert_loss_from_start: 0" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Start Line', distance_from_start: 100, vert_gain_from_start: 100, vert_loss_from_start: 100, sub_order: 0, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("for the start split must be 0")
    expect(split.errors[:vert_gain_from_start]).to include("for the start split must be 0")
    expect(split.errors[:vert_loss_from_start]).to include("for the start split must be 0")
  end

  it "should require waypoint splits and finish splits to have positive distance_from_start" do
    split1 = Split.new(course_id: 1, location_id: 1, name: 'Aid1 In', distance_from_start: 0, sub_order: 0, kind: 2)
    split2 = Split.new(course_id: 1, location_id: 1, name: 'Finish Line', distance_from_start: 0, sub_order: 0, kind: 1)
    expect(split1).not_to be_valid
    expect(split1.errors[:distance_from_start]).to include("must be positive for waypoint and finish splits")
    expect(split2).not_to be_valid
    expect(split2.errors[:distance_from_start]).to include("must be positive for waypoint and finish splits")
  end

  it "should not have negative vert_gain_from_start" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Test', distance_from_start: 6000, vert_gain_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_gain_from_start]).to include("may not be negative")
  end

  it "should not have negative vert_loss_from_start" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Test', distance_from_start: 6000, vert_loss_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_loss_from_start]).to include("may not be negative")
  end

  describe 'waypoint_group' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, first_start_time: Time.current) }
    let(:event_same_course) { Event.create!(name: 'Waypoint Event on same course', course: course, first_start_time: Time.current) }

    before do
      event.splits.create!(course: course, location_id: 1, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      event.splits.create!(course: course, location_id: 2, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, location_id: 2, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, location_id: 3, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)

      event_same_course.splits.create!(course: course, location_id: 2, name: 'Monarch Pass pre 2000 In', distance_from_start: 4400, sub_order: 0, kind: :waypoint)
      event_same_course.splits.create!(course: course, location_id: 2, name: 'Monarch Pass pre 2000 Out', distance_from_start: 4400, sub_order: 1, kind: :waypoint)
      event_same_course.splits.create!(course: course, location_id: 2, name: 'Monarch Pass 2012 flood In', distance_from_start: 4400, sub_order: 3, kind: :waypoint)
      event_same_course.splits.create!(course: course, location_id: 2, name: 'Monarch Pass 2012 flood Out', distance_from_start: 4400, sub_order: 4, kind: :waypoint)

      other_course = Course.create!(name: 'some other course')
      Event.create!(name: 'Event on some other course', course: other_course, first_start_time: Time.current)
      Split.create!(course: other_course, location_id: 1, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      Split.create!(course: other_course, location_id: 2, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      Split.create!(course: other_course, location_id: 2, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      Split.create!(course: other_course, location_id: 3, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
      Event.create!(name: 'Other Waypoint Event', course: other_course, first_start_time: Time.current)
    end

    it 'should setup the data correctly' do
      expect(Split.count).to eq(12)
      expect(event.splits.count).to eq(4)
      expect(event_same_course.splits.count).to eq(4)
    end

    it 'should return a single split for a start' do
      first_split = course.splits.first
      expect(first_split.waypoint_group.count).to eq(1)
    end

    it 'should return two splits for a waypoint' do
      first_split = course.splits.second
      expect(first_split.waypoint_group.count).to eq(2)
    end

    it 'should return all of the splits for the same distance from start' do
      first_split = event_same_course.splits.first
      expect(first_split.waypoint_group.count).to eq(4)
    end

  end

end