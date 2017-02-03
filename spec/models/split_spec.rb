require 'rails_helper'

# t.integer  "course_id"
# t.integer  "location_id"
# t.string   "base_name"
# t.integer  "distance_from_start"
# t.integer  "vert_gain_from_start"
# t.integer  "vert_loss_from_start"
# t.integer  "kind"
# t.string   "description"
# t.integer  "sub_split_bitmap"

RSpec.describe Split, kind: :model do
  it_behaves_like 'unit_conversions'
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:base_name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }
  let(:persisted_course) { FactoryGirl.create(:course) }
  let(:course1) { FactoryGirl.build_stubbed(:course, name: 'Test Course') }
  let(:course2) { FactoryGirl.build_stubbed(:course, name: 'Test Course 2') }
  let(:location1) { FactoryGirl.build_stubbed(:location, name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105) }

  it 'is valid when created with a course, a name, a distance_from_start, and a kind' do
    Split.create!(course: persisted_course,
                  base_name: 'Hopeless Outbound',
                  distance_from_start: 50000,
                  kind: 2)

    expect(Split.all.count).to(equal(1))
    expect(Split.first.name).to eq('Hopeless Outbound')
    expect(Split.first.distance_from_start).to eq(50000)
    expect(Split.first.sub_split_bitmap).to eq(1) # default value
    expect(Split.first.intermediate?).to eq(true)
  end

  it 'is invalid without a base_name' do
    split = Split.new(course: course1, location: location1, base_name: nil, distance_from_start: 2000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:base_name]).to include("can't be blank")
  end

  it 'is invalid without a distance_from_start' do
    split = Split.new(course: course1, location: location1, base_name: 'Test', distance_from_start: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("can't be blank")
  end

  it 'is invalid without a sub_split_bitmap' do
    split = Split.new(course: course1, location: location1, base_name: 'Test', distance_from_start: 3000, sub_split_bitmap: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:sub_split_bitmap]).to include("can't be blank")
  end

  it 'is invalid without a kind' do
    split = Split.new(course: course1, location: location1, base_name: 'Test', distance_from_start: 6000, kind: nil)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include("can't be blank")
  end

  it 'does not allow duplicate names within the same course' do
    Split.create!(course: persisted_course, base_name: 'Wanderlust', distance_from_start: 7000, kind: 2)
    split = Split.new(course: persisted_course, base_name: 'Wanderlust', distance_from_start: 8000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:base_name]).to include('must be unique for a course')
  end

  it 'allows duplicate names among different courses' do
    Split.create!(course: persisted_course, base_name: 'Wanderlust', distance_from_start: 7000, kind: 2)
    split = Split.new(course: course2, base_name: 'Wanderlust', distance_from_start: 8000, kind: 2)
    expect(split).to be_valid
  end

  it 'does not allow more than one start split within the same course' do
    Split.create!(course: persisted_course, base_name: 'Starting Point', distance_from_start: 0, kind: 0)
    split = Split.new(course: persisted_course, base_name: 'Beginning Point', distance_from_start: 0, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include('only one start split permitted on a course')
  end

  it 'does not allow more than one finish split within the same course' do
    Split.create!(course: persisted_course, base_name: 'Finish Point', distance_from_start: 5000, kind: 1)
    split = Split.new(course: persisted_course, base_name: 'Ending Point', distance_from_start: 5000, kind: 1)
    expect(split).not_to be_valid
    expect(split.errors[:kind]).to include('only one finish split permitted on a course')
  end

  it 'does not allow more than one split with the same distance from start on the same course' do
    Split.create!(course: persisted_course, base_name: 'Aid1', distance_from_start: 9000, kind: 2)
    Split.create!(course: persisted_course, base_name: 'Aid2', distance_from_start: 18000, kind: 2)
    split1 = Split.new(course: persisted_course, base_name: 'Aid1', distance_from_start: 9000, kind: 2)
    split2 = Split.new(course: persisted_course, base_name: 'Aid2', distance_from_start: 18000, kind: 2)
    expect(split1).not_to be_valid
    expect(split2).not_to be_valid
  end

  it 'requires start splits to have distance_from_start: 0, vert_gain_from_start: 0, and vert_loss_from_start: 0' do
    split = Split.new(course: course1, base_name: 'Start Line', distance_from_start: 100, vert_gain_from_start: 100, vert_loss_from_start: 100, kind: 0)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include('for the start split must be 0')
    expect(split.errors[:vert_gain_from_start]).to include('for the start split must be 0')
    expect(split.errors[:vert_loss_from_start]).to include('for the start split must be 0')
  end

  it 'requires intermediate splits and finish splits to have positive distance_from_start' do
    split1 = Split.new(course: course1, base_name: 'Aid1', distance_from_start: 0, kind: 2)
    split2 = Split.new(course: course1, base_name: 'Finish Line', distance_from_start: 0, kind: 1)
    expect(split1).not_to be_valid
    expect(split1.errors[:distance_from_start]).to include('must be positive for intermediate and finish splits')
    expect(split2).not_to be_valid
    expect(split2.errors[:distance_from_start]).to include('must be positive for intermediate and finish splits')
  end

  it 'does not allow negative vert_gain_from_start' do
    split = Split.new(course: course1, base_name: 'Test', distance_from_start: 6000, vert_gain_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_gain_from_start]).to include('may not be negative')
  end

  it 'does not allow negative vert_loss_from_start' do
    split = Split.new(course: course1, base_name: 'Test', distance_from_start: 6000, vert_loss_from_start: -100, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:vert_loss_from_start]).to include('may not be negative')
  end

  describe 'sub_splits' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, start_time: Time.current, laps_required: 1) }
    let(:event_same_course) { Event.create!(name: 'Waypoint Event on same course', course: course, start_time: Time.current, laps_required: 1) }
    let(:event_same_course2) { Event.create!(name: 'Waypoint Event 2 on same course', course: course, start_time: Time.current, laps_required: 1) }

    before do
      event.splits.create!(course: course, base_name: 'Start Point', distance_from_start: 0, sub_split_bitmap: 1, kind: :start)
      event.splits.create!(course: course, base_name: 'Monarch Pass', distance_from_start: 5000, sub_split_bitmap: 65, kind: :intermediate)
      event.splits.create!(course: course, base_name: 'Finish Point', distance_from_start: 50000, sub_split_bitmap: 1, kind: :finish)

      event_same_course.splits.create!(course: course, base_name: 'Monarch Pass pre 2000', distance_from_start: 4400, sub_split_bitmap: 65, kind: :intermediate)
      event_same_course2.splits.create!(course: course, base_name: 'Monarch Pass 2012 flood', distance_from_start: 4500, sub_split_bitmap: 65, kind: :intermediate)

      other_course = Course.create!(name: 'some other course')
      Event.create!(name: 'Event on some other course', course: other_course, start_time: Time.current, laps_required: 1)
      Split.create!(course: other_course, base_name: 'Start Point', distance_from_start: 0, sub_split_bitmap: 1, kind: :start)
      Split.create!(course: other_course, base_name: 'Monarch Pass', distance_from_start: 5000, sub_split_bitmap: 65, kind: :intermediate)
      Split.create!(course: other_course, base_name: 'Finish Point', distance_from_start: 50000, sub_split_bitmap: 1, kind: :finish)
      Event.create!(name: 'Other Waypoint Event', course: other_course, start_time: Time.current, laps_required: 1)
    end

    it 'sets up the data correctly' do
      expect(Split.count).to eq(8)
      expect(event.splits.count).to eq(3)
      expect(event_same_course.splits.count).to eq(1)
      expect(event_same_course2.splits.count).to eq(1)
    end

    it 'returns a single key_hash for a start' do
      first_split = course.splits.first
      expect(first_split.sub_splits.count).to eq(1)
    end

    it 'returns two key_hashes for an intermediate split' do
      first_split = course.splits.second
      expect(first_split.sub_splits.count).to eq(2)
    end

    it 'returns all of the key_hashes for a given split' do
      first_split = event_same_course.splits.first
      expect(first_split.sub_splits.count).to eq(2)
    end
  end

  describe '#in_bitkey and #out_bitkey' do
    it 'returns the in or out bitkey if included in the sub_split bitmap' do
      split = Split.new(sub_split_bitmap: 65)
      expect(split.in_bitkey).to eq(in_bitkey)
      expect(split.out_bitkey).to eq(out_bitkey)
    end

    it 'returns nil only if not included in the sub_split bitmap' do
      split = Split.new(sub_split_bitmap: 64)
      expect(split.in_bitkey).to be_nil
      expect(split.out_bitkey).to eq(out_bitkey)
      split = Split.new(sub_split_bitmap: 1)
      expect(split.out_bitkey).to be_nil
      expect(split.in_bitkey).to eq(in_bitkey)
    end
  end

  context 'when there is no current user (therefore no preferred distance or elevation units)' do
    describe '#distance_as_entered' do
      it 'returns nil if passed an empty string' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = ''
        expect(split.distance_from_start).to be_nil
      end

      it 'returns nil if passed nil' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = nil
        expect(split.distance_from_start).to be_nil
      end

      it 'takes a number in miles and store it as meters (rounded to 0) in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = 5.5
        expect(split.distance_from_start).to eq(8851)
      end

      it 'takes a number string in miles and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = '5'
        expect(split.distance_from_start).to eq(8047)
      end

      it 'ignores commas' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = '1,000'
        expect(split.distance_from_start).to eq(1609344)
      end

      it 'ignores non-numeric characters' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = '5 meters'
        expect(split.distance_from_start).to eq(8047)
      end

      it 'does not ignore decimals' do
        split = Split.new(base_name: 'Test Split')
        split.distance_as_entered = '5.5'
        expect(split.distance_from_start).to eq(8851)
      end

      it 'properly reports values in miles when queried' do
        split = Split.new(base_name: 'Test Split', distance_from_start: 8851)
        expect(split.distance_as_entered).to eq(5.5)
      end
    end

    describe 'vert_gain_as_entered and vert_loss_as_entered' do
      it 'returns nil if passed an empty string' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = ''
        split.vert_loss_as_entered = ''
        expect(split.vert_gain_from_start).to be_nil
        expect(split.vert_loss_from_start).to be_nil
      end

      it 'returns nil if passed nil' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = nil
        split.vert_loss_as_entered = nil
        expect(split.vert_gain_from_start).to be_nil
        expect(split.vert_loss_from_start).to be_nil
      end

      it 'takes a number in feet and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = 13500
        split.vert_loss_as_entered = 12000
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
        expect(split.vert_loss_from_start.round(1)).to eq(3657.6)
      end

      it 'takes a number string in feet and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = '13500'
        split.vert_loss_as_entered = '12000'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
        expect(split.vert_loss_from_start.round(1)).to eq(3657.6)
      end

      it 'ignores commas' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = '13,500'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
      end

      it 'ignores non-numeric characters' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = '13500 meters'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
      end

      it 'does not ignore decimals' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_as_entered = '13,500.5'
        expect(split.vert_gain_from_start.round(1)).to eq(4115.0)
      end

      it 'properly reports values in feet when queried' do
        split = Split.new(base_name: 'Test Split', vert_gain_from_start: 4114.8, vert_loss_from_start: 3657.6)
        expect(split.vert_gain_as_entered).to eq(13500)
        expect(split.vert_loss_as_entered).to eq(12000)
      end
    end
  end
end