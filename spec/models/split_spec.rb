require "rails_helper"

# t.integer  "course_id"
# t.integer  "location_id"
# t.string   "base_name"
# t.integer  "distance_from_start"
# t.integer  "vert_gain_from_start"
# t.integer  "vert_loss_from_start"
# t.integer  "kind"
# t.string   "description"
# t.integer  "sub_split_mask"

RSpec.describe Split, kind: :model do
  it { is_expected.to strip_attribute(:base_name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  before :each do
    @course1 = Course.create!(name: 'Test Course')
    @course2 = Course.create!(name: 'Test Course 2')
    @location1 = Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
    @location2 = Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    @location3 = Location.create(name: 'Mountain Getaway', elevation: 2950, latitude: 40.3, longitude: -105.15)
    @sub_split1 = SubSplit.create!(bitkey: 1, kind: 'In')
    @sub_split2 = SubSplit.create!(bitkey: 2, kind: 'Out')
  end

  it "should be valid when created with a course_id, a name, a distance_from_start, and a kind" do
    Split.create!(course_id: @course1.id,
                  base_name: 'Hopeless Outbound',
                  distance_from_start: 50000,
                  kind: 2)

    expect(Split.all.count).to(equal(1))
    expect(Split.first.name).to eq('Hopeless Outbound')
    expect(Split.first.distance_from_start).to eq(50000)
    expect(Split.first.sub_split_mask).to eq(1)    # default value
    expect(Split.first.intermediate?).to eq(true)
  end

  it "should be invalid without a base_name" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: nil, distance_from_start: 2000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:base_name]).to include("can't be blank")
  end

  it "should be invalid without a distance_from_start" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Test', distance_from_start: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("can't be blank")
  end

  it "should be invalid without a sub_split_mask" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Test', distance_from_start: 3000, sub_split_mask: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:sub_split_mask]).to include("can't be blank")
  end

  it "should be invalid without a kind" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Test', distance_from_start: 6000, kind: nil)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("can't be blank")
  end

  it "should not allow duplicate names within the same course" do
    Split.create!(course_id: @course1.id, location_id: @location1.id, base_name: 'Wanderlust', distance_from_start: 7000, kind: 2)
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Wanderlust', distance_from_start: 8000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:base_name]).to include("must be unique for a course")
  end

  it "should allow duplicate names among different courses" do
    Split.create!(course_id: @course1.id, location_id: @location1.id, base_name: 'Wanderlust', distance_from_start: 7000, kind: 2)
    split = Split.new(course_id: @course2.id, location_id: @location1.id, base_name: 'Wanderlust', distance_from_start: 8000, kind: 2)
    expect(split).to be_valid
  end
  
  it "should not allow more than one start split within the same course" do
    Split.create!(course_id: @course1.id, location_id: @location1.id, base_name: 'Starting Point', distance_from_start: 0, kind: 0)
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Beginning Point', distance_from_start: 0, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("only one start split permitted on a course")
  end

  it "should not allow more than one finish split within the same course" do
    Split.create!(course_id: @course1.id, location_id: @location1.id, base_name: 'Finish Point', distance_from_start: 5000, kind: 1)
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Ending Point', distance_from_start: 5000, kind: 1)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("only one finish split permitted on a course")
  end

  it "should not allow more than one split with the same distance from start on the same course" do
    Split.create!(course_id: @course1.id, location_id: @location1.id, base_name: 'Aid1', distance_from_start: 9000, kind: 2)
    Split.create!(course_id: @course1.id, location_id: @location2.id, base_name: 'Aid2', distance_from_start: 18000, kind: 2)
    split1 = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Aid1', distance_from_start: 9000, kind: 2)
    split2 = Split.new(course_id: @course1.id, location_id: @location2.id, base_name: 'Aid2', distance_from_start: 18000, kind: 2)
    expect(split1).not_to be_valid
    expect(split2).not_to be_valid
  end

  it "should require start splits to have distance_from_start: 0, vert_gain_from_start: 0, and vert_loss_from_start: 0" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Start Line', distance_from_start: 100, vert_gain_from_start: 100, vert_loss_from_start: 100, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("for the start split must be 0")
    expect(split.errors[:vert_gain_from_start]).to include("for the start split must be 0")
    expect(split.errors[:vert_loss_from_start]).to include("for the start split must be 0")
  end

  it "should require intermediate splits and finish splits to have positive distance_from_start" do
    split1 = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Aid1', distance_from_start: 0, kind: 2)
    split2 = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Finish Line', distance_from_start: 0, kind: 1)
    expect(split1).not_to be_valid
    expect(split1.errors[:distance_from_start]).to include("must be positive for intermediate and finish splits")
    expect(split2).not_to be_valid
    expect(split2.errors[:distance_from_start]).to include("must be positive for intermediate and finish splits")
  end

  it "should not have negative vert_gain_from_start" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Test', distance_from_start: 6000, vert_gain_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_gain_from_start]).to include("may not be negative")
  end

  it "should not have negative vert_loss_from_start" do
    split = Split.new(course_id: @course1.id, location_id: @location1.id, base_name: 'Test', distance_from_start: 6000, vert_loss_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_loss_from_start]).to include("may not be negative")
  end

  describe 'sub_split_key_hashes' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, start_time: Time.current) }
    let(:event_same_course) { Event.create!(name: 'Waypoint Event on same course', course: course, start_time: Time.current) }
    let(:event_same_course2) { Event.create!(name: 'Waypoint Event 2 on same course', course: course, start_time: Time.current) }

    before do
      event.splits.create!(course: course, location_id: @location1.id, base_name: 'Start Point', distance_from_start: 0, sub_split_mask: 1, kind: :start)
      event.splits.create!(course: course, location_id: @location2.id, base_name: 'Monarch Pass', distance_from_start: 5000, sub_split_mask: 65, kind: :intermediate)
      event.splits.create!(course: course, location_id: @location3.id, base_name: 'Finish Point', distance_from_start: 50000, sub_split_mask: 1, kind: :finish)

      event_same_course.splits.create!(course: course, location_id: @location2.id, base_name: 'Monarch Pass pre 2000', distance_from_start: 4400, sub_split_mask: 65, kind: :intermediate)
      event_same_course2.splits.create!(course: course, location_id: @location2.id, base_name: 'Monarch Pass 2012 flood', distance_from_start: 4500, sub_split_mask: 65, kind: :intermediate)

      other_course = Course.create!(name: 'some other course')
      Event.create!(name: 'Event on some other course', course: other_course, start_time: Time.current)
      Split.create!(course: other_course, location_id: @location1.id, base_name: 'Start Point', distance_from_start: 0, sub_split_mask: 1, kind: :start)
      Split.create!(course: other_course, location_id: @location2.id, base_name: 'Monarch Pass', distance_from_start: 5000, sub_split_mask: 65, kind: :intermediate)
      Split.create!(course: other_course, location_id: @location3.id, base_name: 'Finish Point', distance_from_start: 50000, sub_split_mask: 1, kind: :finish)
      Event.create!(name: 'Other Waypoint Event', course: other_course, start_time: Time.current)
    end

    it 'should setup the data correctly' do
      expect(Split.count).to eq(8)
      expect(event.splits.count).to eq(3)
      expect(event_same_course.splits.count).to eq(1)
      expect(event_same_course2.splits.count).to eq(1)
    end

    it 'should return a single key_hash for a start' do
      first_split = course.splits.first
      expect(first_split.sub_split_key_hashes.count).to eq(1)
    end

    it 'should return two key_hashes for an intermediate split' do
      first_split = course.splits.second
      expect(first_split.sub_split_key_hashes.count).to eq(2)
    end

    it 'should return all of the key_hashes for a given split' do
      first_split = event_same_course.splits.first
      expect(first_split.sub_split_key_hashes.count).to eq(2)
    end
  end

end