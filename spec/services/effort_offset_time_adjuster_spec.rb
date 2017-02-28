require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortOffsetTimeAdjuster do
  before do
    FactoryGirl.reload
  end

  let(:split_times_100) { FactoryGirl.build_stubbed_list(:split_times_hardrock_45, 4) }
  let(:test_effort) { FactoryGirl.build_stubbed(:effort, event_id: 50) }

  describe '#initialize' do
    it 'initializes with an effort and split_times in an args hash' do
      effort = test_effort
      split_times = split_times_100
      expect { EffortOffsetTimeAdjuster.new(effort: effort, split_times: split_times) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no effort is given' do
      split_times = split_times_100
      expect { EffortOffsetTimeAdjuster.new(split_times: split_times) }
          .to raise_error(/must include effort/)
    end
  end

  describe '#assign_adjustments' do
    context 'when start_offset has been changed' do
      it 'adjusts all times_from_start (other than the start split_time) by the negative of the change in start_offset' do
        effort = test_effort
        split_times = split_times_100
        allow(effort).to receive(:split_times).and_return(split_times)
        start_offset = 100
        validate_adjustments(effort, split_times, start_offset)
      end

      it 'functions properly when start_offset is adjusted by a negative value' do
        effort = test_effort
        split_times = split_times_100
        allow(effort).to receive(:split_times).and_return(split_times)
        start_offset = -100
        validate_adjustments(effort, split_times, start_offset)
      end

      it 'functions properly when start_offset is not adjusted' do
        effort = test_effort
        split_times = split_times_100
        allow(effort).to receive(:split_times).and_return(split_times)
        start_offset = 0
        validate_adjustments(effort, split_times, start_offset)
      end

      it 'does not fail when the effort has no split_times' do
        effort = test_effort
        split_times = []
        allow(effort).to receive(:split_times).and_return(split_times)
        start_offset = 100
        validate_adjustments(effort, split_times, start_offset)
      end

      def validate_adjustments(effort, split_times, start_offset)
        unadjusted_times = split_times.map(&:time_from_start)
        expect(effort.start_offset).to eq(0)
        effort.start_offset = start_offset
        adjuster = EffortOffsetTimeAdjuster.new(effort: effort, split_times: split_times)
        adjuster.assign_adjustments
        expect(split_times.map(&:time_from_start)[0]).to eq(unadjusted_times[0])
        expect(split_times.map(&:time_from_start)[1..-1]).to eq(unadjusted_times.map { |tfs| tfs - start_offset }[1..-1])
      end
    end
  end
end