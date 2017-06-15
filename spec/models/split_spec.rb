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
  it { is_expected.to strip_attribute(:base_name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }
  let(:persisted_course) { FactoryGirl.create(:course) }
  let(:course1) { FactoryGirl.build_stubbed(:course, name: 'Test Course') }
  let(:course2) { FactoryGirl.build_stubbed(:course, name: 'Test Course 2') }

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
    split = Split.new(course: course1, base_name: nil, distance_from_start: 2000, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:base_name]).to include("can't be blank")
  end

  it 'is invalid without a distance_from_start' do
    split = Split.new(course: course1, base_name: 'Test', distance_from_start: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include("can't be blank")
  end

  it 'is invalid without a sub_split_bitmap' do
    split = Split.new(course: course1, base_name: 'Test', distance_from_start: 3000, sub_split_bitmap: nil, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:sub_split_bitmap]).to include("can't be blank")
  end

  it 'is invalid without a kind' do
    split = Split.new(course: course1, base_name: 'Test', distance_from_start: 6000, kind: nil)
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

  it 'does not allow an intermediate split with distance_from_start great than the finish split distance_from_start' do
    skip
    Split.create!(course: persisted_course, base_name: 'Ending point', distance_from_start: 100, kind: 1)
    split = Split.new(course: persisted_course, base_name: 'Aid Station', distance_from_start: 200, kind: 2)
    expect(split).not_to be_valid
    expect(split.errors[:distance_from_start]).to include('must be less than the finish split distance_from_start')
  end

  describe '#sub_splits' do
    it 'returns a single key_hash for a start split' do
      split = FactoryGirl.build_stubbed(:start_split)
      expect(split.sub_splits.size).to eq(1)
      expect(split.sub_splits.first).to eq({split.id => in_bitkey})
    end

    it 'returns two key_hashes for an intermediate split' do
      split = FactoryGirl.build_stubbed(:split)
      expect(split.sub_splits.size).to eq(2)
      expect(split.sub_splits).to eq([{split.id => in_bitkey}, {split.id => out_bitkey}])
    end

    it 'returns a single key_hash for a finish split' do
      split = FactoryGirl.build_stubbed(:finish_split)
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
            entries: [{split_id: split.id, sub_split: 'in', label: split.name(in_bitkey)},
                      {split_id: split.id, sub_split: 'out', label: split.name(out_bitkey)}]
        }
        expect(split.live_entry_attributes).to eq(expected)
      end

      context 'when a split has only an in sub_split' do
        let(:split) { build_stubbed(:split, sub_split_bitmap: 1) }

        it 'returns a single-item array with button label, sub_split, and split_id' do
          expected = [{split_id: split.id, sub_split: 'in', label: split.name(in_bitkey)}]
          expect(split.live_entry_attributes).to eq(expected)
        end
      end
    end
  end
end
