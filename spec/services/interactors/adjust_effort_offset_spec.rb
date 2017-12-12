require 'rails_helper'

RSpec.describe Interactors::AdjustEffortOffset do
  subject { Interactors::AdjustEffortOffset.new(effort) }
  let(:course) { create(:course_with_standard_splits, splits_count: 3) }
  let(:event) { create(:event, course: course, laps_required: 1) }
  let(:effort) { create(:effort, event: event) }

  describe '#initialize' do
    context 'when an effort is provided' do
      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no effort is provided' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end
  end

  describe '#perform!' do
    before do
      event.splits << course.splits
      time_points = event.required_lap_splits.map(&:time_points).flatten
      SplitTime.create!(effort: effort, time_point: time_points.first, time_from_start: 0)
      SplitTime.create!(effort: effort, time_point: time_points.second, time_from_start: 1000)
      SplitTime.create!(effort: effort, time_point: time_points.third, time_from_start: 2000)
      SplitTime.create!(effort: effort, time_point: time_points.fourth, time_from_start: 3000)
    end

    before { expect(effort.start_offset).to eq(0) }

    context 'when start_offset has been changed to a positive value' do
      before { effort.start_offset = 100 }

      it 'adjusts all times_from_start (other than the start split_time) by the negative of the change in start_offset' do
        validate_adjustments(100)
      end
    end

    context 'when start_offset has been changed to a negative value' do
      before { effort.start_offset = -100 }

      it 'functions properly' do
        validate_adjustments(-100)
      end
    end

    context 'when start_offset is not adjusted' do
      before { effort.start_offset = 0 }

      it 'functions properly when start_offset is not adjusted' do
        response = validate_adjustments(0)
        expect(response).to be_successful
        expect(response.message).to eq("Start offset for #{effort} was not changed. ")
      end
    end

    context 'when start_offset moves forward beyond the time of any non-start split_time' do
      before { effort.start_offset = 1200 }

      it 'does not adjust start_times and reports an error' do
        response = validate_adjustments(0)
        expect(response.errors.first[:title]).to eq("SplitTime #{effort.ordered_split_times.second} could not be saved")
        expect(response.errors.first[:detail][:messages]).to include("Time from start must be greater than or equal to 0")
      end
    end

    context 'when the effort has no split_times' do
      before { allow(effort).to receive(:split_times).and_return([]) }

      it 'does not fail' do
        validate_adjustments(0)
      end
    end

    def validate_adjustments(start_offset)
      unadjusted_times = effort.ordered_split_times.map(&:time_from_start)
      response = subject.perform!
      effort.reload
      adjusted_times = effort.ordered_split_times.map(&:time_from_start)
      expect(adjusted_times[0]).to eq(unadjusted_times[0])
      expect(adjusted_times[1..-1]).to eq(unadjusted_times.map { |tfs| tfs - start_offset }[1..-1])
      response
    end
  end
end
