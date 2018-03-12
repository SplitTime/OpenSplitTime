require 'rails_helper'

# t.integer  "course_id"
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
  it_behaves_like 'locatable'
  it { is_expected.to strip_attribute(:base_name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }
  let(:persisted_course) { create(:course) }
  let(:course1) { build_stubbed(:course, name: 'Test Course') }
  let(:course2) { build_stubbed(:course, name: 'Test Course 2') }

  describe '#initialize' do
    it 'is valid when created with a course, a name, a distance_from_start, and a kind' do
      Split.create!(course: persisted_course,
                    base_name: 'Hopeless Outbound',
                    distance_from_start: 50000,
                    kind: :intermediate)

      expect(Split.all.count).to(equal(1))
      expect(Split.first.name).to eq('Hopeless Outbound')
      expect(Split.first.distance_from_start).to eq(50000)
      expect(Split.first.sub_split_bitmap).to eq(1) # default value
      expect(Split.first.intermediate?).to eq(true)
    end

    it 'is invalid without a base_name' do
      split = build_stubbed(:split, base_name: nil)
      expect(split).not_to be_valid
      expect(split.errors[:base_name]).to include("can't be blank")
    end

    it 'is invalid without a distance_from_start' do
      split = build_stubbed(:split, distance_from_start: nil)
      expect(split).not_to be_valid
      expect(split.errors[:distance_from_start]).to include("can't be blank")
    end

    it 'is invalid without a sub_split_bitmap' do
      split = build_stubbed(:split, sub_split_bitmap: nil)
      expect(split).not_to be_valid
      expect(split.errors[:sub_split_bitmap]).to include("can't be blank")
    end

    it 'is invalid without a kind' do
      split = build_stubbed(:split, kind: nil)
      expect(split).not_to be_valid
      expect(split.errors[:kind]).to include("can't be blank")
    end

    it 'does not allow duplicate names within the same course' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: persisted_course, base_name: split_1.base_name)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:base_name]).to include('must be unique for a course')
    end

    it 'ignores case when validating uniqueness of names within the same course' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: persisted_course, base_name: split_1.base_name.upcase)
      expect(split_1.base_name).not_to eq(split_2.base_name)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:base_name]).to include('must be unique for a course')
    end

    it 'ignores dash separators when validating uniqueness of names within the same course' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: persisted_course, base_name: split_1.base_name.split.join('-'))
      expect(split_1.base_name).not_to eq(split_2.base_name)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:base_name]).to include('must be unique for a course')
    end

    it 'ignores extra spaces when validating uniqueness of names within the same course' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: persisted_course, base_name: split_1.base_name.split.join('  '))
      expect(split_1.base_name).not_to eq(split_2.base_name)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:base_name]).to include('must be unique for a course')
    end

    it 'allows duplicate names among different courses' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: course2, base_name: split_1.base_name)
      expect(split_2).to be_valid
    end

    it 'does not allow more than one start split within the same course' do
      create(:start_split, course: persisted_course)
      split = build_stubbed(:start_split, course: persisted_course)
      expect(split).not_to be_valid
      expect(split.errors[:kind]).to include('only one start split permitted on a course')
    end

    it 'does not allow more than one finish split within the same course' do
      create(:split, course: persisted_course, kind: :finish)
      split = build_stubbed(:split, course: persisted_course, kind: :finish)
      expect(split).not_to be_valid
      expect(split.errors[:kind]).to include('only one finish split permitted on a course')
    end

    it 'does not allow more than one split with the same distance from start on the same course' do
      split_1 = create(:split, course: persisted_course)
      split_2 = build_stubbed(:split, course: persisted_course, distance_from_start: split_1.distance_from_start)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:distance_from_start]).to include('only one split of a given distance permitted on a course. Use sub_splits if needed.')
    end

    it 'requires start splits to have distance_from_start: 0, vert_gain_from_start: 0, and vert_loss_from_start: 0' do
      split = build_stubbed(:split, distance_from_start: 100, vert_gain_from_start: 100, vert_loss_from_start: 100, kind: :start)
      expect(split).not_to be_valid
      expect(split.errors[:distance_from_start]).to include('for the start split must be 0')
      expect(split.errors[:vert_gain_from_start]).to include('for the start split must be 0')
      expect(split.errors[:vert_loss_from_start]).to include('for the start split must be 0')
    end

    it 'requires intermediate splits and finish splits to have positive distance_from_start' do
      split1 = build_stubbed(:split, distance_from_start: 0, kind: :finish)
      split2 = build_stubbed(:split, distance_from_start: 0, kind: :intermediate)
      expect(split1).not_to be_valid
      expect(split1.errors[:distance_from_start]).to include('must be positive for intermediate and finish splits')
      expect(split2).not_to be_valid
      expect(split2.errors[:distance_from_start]).to include('must be positive for intermediate and finish splits')
    end

    it 'does not allow negative vert_gain_from_start' do
      split = build_stubbed(:split, vert_gain_from_start: -100)
      expect(split).not_to be_valid
      expect(split.errors[:vert_gain_from_start]).to include('may not be negative')
    end

    it 'does not allow negative vert_loss_from_start' do
      split = build_stubbed(:split, vert_loss_from_start: -100)
      expect(split).not_to be_valid
      expect(split.errors[:vert_loss_from_start]).to include('may not be negative')
    end

    it 'does not allow an intermediate split with distance_from_start greater than the finish split distance_from_start' do
      split_1 = create(:split, course: persisted_course, kind: :finish)
      split_2 = build_stubbed(:split, course: persisted_course, distance_from_start: split_1.distance_from_start + 100, kind: :intermediate)
      expect(split_2).not_to be_valid
      expect(split_2.errors[:distance_from_start]).to include('must be less than the finish split distance_from_start')
    end

    it 'allows elevation only within physical limits' do
      split = build_stubbed(:split, elevation: 0)
      expect(split).to be_valid
      split.elevation = -2000
      expect(split).not_to be_valid
      expect(split.errors[:elevation]).to include('must be between -1000 and 10,000 meters')
      split.elevation = 11_000
      expect(split).not_to be_valid
      expect(split.errors[:elevation]).to include('must be between -1000 and 10,000 meters')
    end

    it 'allows latitude only within physical limits' do
      split = build_stubbed(:split, latitude: 40)
      expect(split).to be_valid
      split.latitude = 91
      expect(split).not_to be_valid
      expect(split.errors[:latitude]).to include('must be between -90 and 90')
      split.latitude = -91
      expect(split).not_to be_valid
      expect(split.errors[:latitude]).to include('must be between -90 and 90')
    end

    it 'allows longitude only within physical limits' do
      split = build_stubbed(:split, longitude: -105)
      expect(split).to be_valid
      split.longitude = 181
      expect(split).not_to be_valid
      expect(split.errors[:longitude]).to include('must be between -180 and 180')
      split.longitude = -181
      expect(split).not_to be_valid
      expect(split.errors[:longitude]).to include('must be between -180 and 180')
    end

    context 'for event_group split location validations' do
      let(:event_1) { create(:event, course: course_1, event_group: event_group) }
      let(:event_2) { create(:event, course: course_2, event_group: event_group) }
      let(:event_group) { create(:event_group) }
      let(:course_1) { create(:course) }
      let(:course_1_split_1) { create(:start_split, course: course_1, base_name: 'Start', latitude: 40, longitude: -105) }
      let(:course_1_split_2) { create(:finish_split, course: course_1, base_name: 'Finish', latitude: 42, longitude: -107) }
      let(:course_2) { create(:course) }
      let(:course_2_split_1) { create(:start_split, course: course_2, base_name: 'Start', latitude: 40, longitude: -105) }
      let(:course_2_split_2) { create(:finish_split, course: course_2, base_name: 'Finish', latitude: 42, longitude: -107) }
      before do
        event_1.splits << course_1_split_1
        event_1.splits << course_1_split_2
        event_2.splits << course_2_split_1
        event_2.splits << course_2_split_2
      end

      context 'when split names are duplicated with matching locations within the same event_group' do
        it 'is valid' do
          expect(course_1_split_2).to be_valid
          course_1_split_2.update(base_name: 'Finish')
          expect(course_1_split_2).to be_valid
        end
      end

      context 'when split name changes to match a split with a non-matching location within the same event_group' do
        let(:course_1_split_2) { create(:finish_split, course: course_1, base_name: 'Alternate Finish', latitude: 41, longitude: -106) }

        it 'is invalid' do
          expect(course_1_split_2).to be_valid
          course_1_split_2.update(base_name: 'Finish')
          expect(course_1_split_2).not_to be_valid
          expect(course_1_split_2.errors.full_messages).to include(/Base name Finish is incompatible with similarly named splits within event group/)
        end
      end

      context 'when split location changes to move away from a split with a matching name within the same event_group' do
        let(:course_1_split_2) { create(:finish_split, course: course_1, base_name: 'Finish', latitude: 42, longitude: -107) }

        it 'is invalid' do
          expect(course_1_split_2).to be_valid
          course_1_split_2.update(latitude: 41)
          expect(course_1_split_2).not_to be_valid
          expect(course_1_split_2.errors.full_messages).to include(/Base name Finish is incompatible with similarly named splits within event group/)
        end
      end
    end
  end

  describe '#sub_splits' do
    it 'returns a single key_hash for a start split' do
      split = build_stubbed(:start_split)
      expect(split.sub_splits.size).to eq(1)
      expect(split.sub_splits.first).to eq({split.id => in_bitkey})
    end

    it 'returns two key_hashes for an intermediate split' do
      split = build_stubbed(:split)
      expect(split.sub_splits.size).to eq(2)
      expect(split.sub_splits).to eq([{split.id => in_bitkey}, {split.id => out_bitkey}])
    end

    it 'returns a single key_hash for a finish split' do
      split = build_stubbed(:finish_split)
      expect(split.sub_splits.size).to eq(1)
      expect(split.sub_splits.first).to eq({split.id => in_bitkey})
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

  describe '#name_extensions=' do
    it 'sets sub_split_bitmap to 1 if provided with ["In"]' do
      split = Split.new
      split.name_extensions = %w(In)
      expect(split.sub_split_bitmap).to eq(1)
    end

    it 'sets sub_split_bitmap to 65 if provided with ["In", "Out"]' do
      split = Split.new
      split.name_extensions = %w(In Out)
      expect(split.sub_split_bitmap).to eq(65)
    end

    it 'is unaffacted by different cases in the parameters' do
      split = Split.new
      split.name_extensions = %w(IN out)
      expect(split.sub_split_bitmap).to eq(65)
    end

    it 'functions correctly if passed a single extension as a string' do
      split = Split.new
      split.name_extensions = 'Out'
      expect(split.sub_split_bitmap).to eq(64)
    end

    it 'functions correctly if passed two extensions as a string separated by a space' do
      split = Split.new
      split.name_extensions = 'In Out'
      expect(split.sub_split_bitmap).to eq(65)
    end

    it 'ignores unrecognized extensions' do
      split = Split.new
      split.name_extensions = 'In Hello Out'
      expect(split.sub_split_bitmap).to eq(65)
    end

    it 'sets sub_split_bitmap to 1 if provided with no recognized extensions' do
      split = Split.new
      split.name_extensions = 'Hello There'
      expect(split.sub_split_bitmap).to eq(1)
    end

    it 'sets sub_split_bitmap to 1 if provided with an empty string' do
      split = Split.new
      split.name_extensions = ''
      expect(split.sub_split_bitmap).to eq(1)
    end

    it 'sets sub_split_bitmap to 1 if provided with nil' do
      split = Split.new
      split.name_extensions = nil
      expect(split.sub_split_bitmap).to eq(1)
    end

    it 'is properly aliased as sub_split_kinds=' do
      split = Split.new
      split.sub_split_kinds = %w(In Out)
      expect(split.sub_split_bitmap).to eq(65)
    end
  end

  context 'when there is no current user (therefore no preferred distance or elevation units)' do
    describe '#distance_in_preferred_units' do
      it 'returns nil if passed an empty string' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = ''
        expect(split.distance_from_start).to be_nil
      end

      it 'returns nil if passed nil' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = nil
        expect(split.distance_from_start).to be_nil
      end

      it 'takes a number in miles and store it as meters (rounded to 0) in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = 5.5
        expect(split.distance_from_start).to eq(8851)
      end

      it 'takes a number string in miles and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = '5'
        expect(split.distance_from_start).to eq(8047)
      end

      it 'ignores commas' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = '1,000'
        expect(split.distance_from_start).to eq(1609344)
      end

      it 'ignores non-numeric characters' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = '5 meters'
        expect(split.distance_from_start).to eq(8047)
      end

      it 'does not ignore decimals' do
        split = Split.new(base_name: 'Test Split')
        split.distance_in_preferred_units = '5.5'
        expect(split.distance_from_start).to eq(8851)
      end

      it 'properly reports values in miles when queried' do
        split = Split.new(base_name: 'Test Split', distance_from_start: 8851)
        expect(split.distance_in_preferred_units).to eq(5.5)
      end
    end

    describe 'vert_gain_in_preferred_units and vert_loss_in_preferred_units' do
      it 'returns nil if passed an empty string' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = ''
        split.vert_loss_in_preferred_units = ''
        expect(split.vert_gain_from_start).to be_nil
        expect(split.vert_loss_from_start).to be_nil
      end

      it 'returns nil if passed nil' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = nil
        split.vert_loss_in_preferred_units = nil
        expect(split.vert_gain_from_start).to be_nil
        expect(split.vert_loss_from_start).to be_nil
      end

      it 'takes a number in feet and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = 13500
        split.vert_loss_in_preferred_units = 12000
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
        expect(split.vert_loss_from_start.round(1)).to eq(3657.6)
      end

      it 'takes a number string in feet and store it as meters in the correct attribute' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = '13500'
        split.vert_loss_in_preferred_units = '12000'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
        expect(split.vert_loss_from_start.round(1)).to eq(3657.6)
      end

      it 'ignores commas' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = '13,500'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
      end

      it 'ignores non-numeric characters' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = '13500 meters'
        expect(split.vert_gain_from_start.round(1)).to eq(4114.8)
      end

      it 'does not ignore decimals' do
        split = Split.new(base_name: 'Test Split')
        split.vert_gain_in_preferred_units = '13,500.5'
        expect(split.vert_gain_from_start.round(1)).to eq(4115.0)
      end

      it 'properly reports values in feet when queried' do
        split = Split.new(base_name: 'Test Split', vert_gain_from_start: 4114.8, vert_loss_from_start: 3657.6)
        expect(split.vert_gain_in_preferred_units).to eq(13500)
        expect(split.vert_loss_in_preferred_units).to eq(12000)
      end
    end
  end

  describe '#live_entry_attributes' do
    context 'when a split has in and out sub_splits' do
      let(:split) { build_stubbed(:split, sub_split_bitmap: 65) }

      it 'returns an array with a title and an array of button labels, sub_splits, and split_ids' do
        expected = {
            title: split.base_name,
            entries: [{split_id: split.id, sub_split_kind: 'in', label: split.name(in_bitkey)},
                      {split_id: split.id, sub_split_kind: 'out', label: split.name(out_bitkey)}]
        }
        expect(split.live_entry_attributes).to eq(expected)
      end

      context 'when a split has only an in sub_split' do
        let(:split) { build_stubbed(:split, sub_split_bitmap: 1) }

        it 'returns a single-item array with button label, sub_split, and split_id' do
          expected = {title: split.base_name,
                      entries: [{split_id: split.id, sub_split_kind: 'in', label: split.name(in_bitkey)}]}
          expect(split.live_entry_attributes).to eq(expected)
        end
      end
    end
  end

  describe '#parameterized_base_name' do
    let(:split) { build_stubbed(:split, base_name: 'Aid Station 1') }

    it 'returns a parameterized version of the base_name' do
      expect(split.parameterized_base_name).to eq('aid-station-1')
    end
  end
end
