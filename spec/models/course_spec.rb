# frozen_string_literal: true

require 'rails_helper'

# t.string "name", limit: 64, null: false
# t.text "description"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.integer "created_by"
# t.integer "updated_by"
# t.datetime "next_start_time"
# t.string "slug", null: false
# t.string "gpx_file_name"
# t.string "gpx_content_type"
# t.integer "gpx_file_size"
# t.datetime "gpx_updated_at"

RSpec.describe Course, type: :model do
  include BitkeyDefinitions

  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  describe '#initialize' do
    it 'is valid with a name' do
      course = Course.create!(name: 'Slow Mo 100 CCW')

      expect(Course.all.count).to(equal(1))
      expect(course).to be_valid
    end

    it 'is invalid without a name' do
      course = Course.new(name: nil)
      expect(course).not_to be_valid
      expect(course.errors[:name]).to include("can't be blank")
    end

    it 'does not allow duplicate names' do
      Course.create!(name: 'Hard Time 100')
      course = Course.new(name: 'Hard Time 100')
      expect(course).not_to be_valid
      expect(course.errors[:name]).to include('has already been taken')
    end
  end

  describe 'methods that produce lap_splits' do
    let(:course) { build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course.splits }
    let(:split_ids) { splits.map(&:id) }

    describe '#cycled_lap_splits' do
      let(:lap_splits) { course.cycled_lap_splits.first(number) }

      context 'when called with first(0)' do
        let(:number) { 0 }

        it 'returns an empty array when called with first(0)' do
          expect(lap_splits).to eq([])
        end
      end

      context 'when called with a number greater than 0' do
        let(:number) { 10 }

        it 'returns an array of that number of ordered TimePoints for the event' do
          expect(lap_splits.size).to eq(number)
          expect(lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4 + [3] * 2)
          expect(lap_splits.map(&:split_id)).to eq(split_ids * 2 + split_ids.first(2))
        end
      end
    end

    describe '#lap_splits_through' do
      let(:lap_splits) { course.lap_splits_through(laps) }

      context 'when lap is 0' do
        let(:laps) { 0 }

        it 'returns an empty array when called with first(0)' do
          expect(lap_splits).to eq([])
        end
      end

      context 'when lap is greater than 0' do
        let(:laps) { 2 }

        it 'returns an array of lap_splits through the provided lap number' do
          expect(lap_splits.size).to eq(laps * splits.size)
          expect(lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
          expect(lap_splits.map(&:split_id)).to eq(split_ids * 2)
        end
      end
    end
  end

  describe 'methods that produce time_points' do
    let(:course) { build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course.splits }
    let(:expected_split_ids) { [splits.first, splits.second, splits.second, splits.third, splits.third, splits.fourth].map(&:id) }
    let(:expected_bitkeys) { [in_bitkey, in_bitkey, out_bitkey, in_bitkey, out_bitkey, in_bitkey] }

    describe '#cycled_time_points' do
      let(:time_points) { course.cycled_time_points.first(number) }

      context 'when called with first(0)' do
        let(:number) { 0 }

        it 'returns an empty array when called with first(0)' do
          expect(time_points).to eq([])
        end
      end

      context 'when called with a number greater than 0' do
        let(:number) { 15 }

        it 'returns an array of that number of ordered TimePoints for the event' do
          expect(time_points.size).to eq(number)
          expect(time_points.map(&:lap)).to eq([1] * 6 + [2] * 6 + [3] * 3)
          expect(time_points.map(&:split_id)).to eq(expected_split_ids * 2 + expected_split_ids.first(3))
          expect(time_points.map(&:bitkey)).to eq(expected_bitkeys * 2 + expected_bitkeys.first(3))
        end
      end
    end

    describe '#time_points_through' do
      let(:time_points) { course.time_points_through(laps) }

      context 'when lap is 0' do
        let(:laps) { 0 }

        it 'returns an empty array when called with first(0)' do
          expect(time_points).to eq([])
        end
      end

      context 'when lap is greater than 0' do
        let(:laps) { 2 }

        it 'returns an array of ordered TimePoints for that number of laps' do
          expect(time_points.size).to eq(laps * expected_split_ids.size)
          expect(time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
          expect(time_points.map(&:split_id)).to eq(expected_split_ids * 2)
          expect(time_points.map(&:bitkey)).to eq(expected_bitkeys * 2)
        end
      end
    end
  end

  describe '#distance' do
    it 'returns a course distance using the distance_from_start of the finish split' do
      course = build_stubbed(:course_with_standard_splits)
      course.splits.last.distance_from_start = 200
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.distance).to eq(200)
    end

    it 'returns nil if no finish split exists on the course' do
      course = build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.distance).to be_nil
    end
  end

  describe '#vert_gain' do
    it 'returns a course vert_gain using the vert_gain_from_start of the finish split' do
      course = build_stubbed(:course_with_standard_splits)
      course.splits.last.vert_gain_from_start = 100
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.vert_gain).to eq(100)
    end

    it 'returns nil if no finish split exists on the course' do
      course = build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.vert_gain).to be_nil
    end
  end

  describe '#vert_loss' do
    it 'returns a course vert_loss using the vert_loss_from_start of the finish split' do
      course = build_stubbed(:course_with_standard_splits)
      course.splits.last.vert_loss_from_start = 50
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.vert_loss).to eq(50)
    end

    it 'returns nil if no finish split exists on the course' do
      course = build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.vert_loss).to be_nil
    end
  end

  describe '#simple?' do
    subject { course.simple? }
    let(:course) { build_stubbed(:course, splits: splits) }

    context 'when the course has only a start and finish split' do
      let(:splits) { build_stubbed_list(:split, 2) }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the course has more than two splits' do
      let(:splits) { build_stubbed_list(:split, 3) }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
