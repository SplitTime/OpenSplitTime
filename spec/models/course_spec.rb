# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Course, type: :model do
  include BitkeyDefinitions

  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }
  it { is_expected.to localize_time_attribute(:next_start_time) }

  describe '#initialize' do
    it 'is valid with a name' do
      course = Course.create!(name: 'Slow Mo 100 CCW')
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
    let(:course) { courses(:rufa_course) }
    let(:splits) { course.ordered_splits }
    let(:split_ids) { splits.map(&:id) }

    describe '#cycled_lap_splits' do
      let(:lap_splits) { course.cycled_lap_splits.first(number) }

      context 'when called with first(0)' do
        let(:number) { 0 }

        it 'returns an empty array' do
          expect(lap_splits).to eq([])
        end
      end

      context 'when called with a number greater than 0' do
        let(:number) { 8 }

        it 'returns an array of that number of ordered TimePoints for the event' do
          expect(lap_splits.size).to eq(number)
          expect(lap_splits.map(&:lap)).to eq([1] * 3 + [2] * 3 + [3] * 2)
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
          expect(lap_splits.map(&:lap)).to eq([1] * 3 + [2] * 3)
          expect(lap_splits.map(&:split_id)).to eq(split_ids * 2)
        end
      end
    end
  end

  describe 'methods that produce time_points' do
    let(:course) { courses(:rufa_course) }
    let(:splits) { course.ordered_splits }
    let(:split_ids) { splits.map(&:id) }

    describe '#cycled_time_points' do
      let(:time_points) { course.cycled_time_points.first(number) }

      context 'when called with first(0)' do
        let(:number) { 0 }

        it 'returns an empty array when called with first(0)' do
          expect(time_points).to eq([])
        end
      end

      context 'when called with a number greater than 0' do
        let(:number) { 8 }

        it 'returns an array of that number of ordered TimePoints for the event' do
          expect(time_points.size).to eq(number)
          expect(time_points.map(&:lap)).to eq([1] * 3 + [2] * 3 + [3] * 2)
          expect(time_points.map(&:split_id)).to eq(split_ids * 2 + split_ids.first(2))
          expect(time_points.map(&:bitkey)).to all eq(in_bitkey)
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
          expect(time_points.size).to eq(laps * 3)
          expect(time_points.map(&:lap)).to eq([1] * 3 + [2] * 3)
          expect(time_points.map(&:split_id)).to eq(split_ids * 2)
          expect(time_points.map(&:bitkey)).to all eq(in_bitkey)
        end
      end
    end
  end

  describe '#distance' do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it 'returns a course distance using the distance_from_start of the finish split' do
      expect(course.distance).to eq(finish_split.distance_from_start)
    end

    it 'returns nil if no finish split exists on the course' do
      allow(course).to receive(:finish_split).and_return([])
      expect(course.distance).to be_nil
    end
  end

  describe '#vert_gain' do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it 'returns a course vert_gain using the distance_from_start of the finish split' do
      expect(course.vert_gain).to eq(finish_split.vert_gain_from_start)
    end

    it 'returns nil if no finish split exists on the course' do
      allow(course).to receive(:finish_split).and_return([])
      expect(course.vert_gain).to be_nil
    end
  end

  describe '#vert_loss' do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it 'returns a course vert_loss using the distance_from_start of the finish split' do
      expect(course.vert_loss).to eq(finish_split.vert_loss_from_start)
    end

    it 'returns nil if no finish split exists on the course' do
      allow(course).to receive(:finish_split).and_return([])
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
