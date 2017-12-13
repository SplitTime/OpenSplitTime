require 'rails_helper'

RSpec.describe Interactors::AdjustEffortOffset do
  before { FactoryGirl.reload }

  subject { Interactors::AdjustEffortOffset.new(effort) }
  let(:event) { build_stubbed(:event_functional, efforts_count: 1) }
  let(:effort) { event.efforts.first }
  let(:split_times) { effort.ordered_split_times }
  let(:start_split_time) { split_times.first }
  let(:other_split_times) { split_times[1..-1]}

  describe '#initialize' do
    context 'when an effort is provided' do
      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no effort is provided' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/arguments must include a subject/)
      end
    end
  end

  describe '#perform' do
    before { expect(start_split_time.time_from_start).to eq(0) }

    context 'when starting split_time is a positive value' do
      before { start_split_time.time_from_start = 100 }

      it 'adjusts start split time to 0 and adjusts other values as expected' do
        response = validate_adjustments(100)
        expect(start_split_time.time_from_start).to eq(0)
        expect(response).to be_successful
        expect(response.message).to eq("Start offset for #{effort} was changed to 100. Split times were adjusted backward by 100.0 seconds to maintain absolute times. ")
      end
    end

    context 'when starting split_time is a negative value' do
      before { start_split_time.time_from_start = -100 }

      it 'adjusts start split time to 0 and adjusts other values as expected' do
        response = validate_adjustments(-100)
        expect(start_split_time.time_from_start).to eq(0)
        expect(response).to be_successful
        expect(response.message).to eq("Start offset for #{effort} was changed to -100. Split times were adjusted forward by 100.0 seconds to maintain absolute times. ")
      end
    end

    context 'when starting split_time is zero' do
      before { start_split_time.time_from_start = 0 }

      it 'makes no changes' do
        response = validate_adjustments(0)
        expect(start_split_time.time_from_start).to eq(0)
        expect(response).to be_successful
        expect(response.message).to eq("Start offset for #{effort} was not changed. ")
      end
    end

    context 'when starting split_time.time_from_start is larger than a later split_time.time_from_start' do
      before { start_split_time.time_from_start = other_split_times.first.time_from_start + 100 }

      it 'does not adjust start_times and reports an error' do
        response = validate_adjustments(0)
        expect(start_split_time.time_from_start).to eq(other_split_times.first.time_from_start + 100)
        expect(response.errors.first[:title]).to eq("Effort offset could not be adjusted")
        expect(response.errors.first[:detail][:messages]).to include("The starting split time for #{effort} was beyond an existing later split time")
      end
    end

    context 'when the effort has no split_times' do
      before { allow(effort).to receive(:split_times).and_return([]) }

      it 'does not fail' do
        response = validate_adjustments(0)
        expect(response).to be_successful
        expect(response.message).to eq("Start offset for #{effort} was not changed. ")
      end
    end

    def validate_adjustments(start_offset)
      unadjusted_times = other_split_times.map(&:time_from_start)
      response = subject.perform
      adjusted_times = other_split_times.map(&:time_from_start)
      expect(effort.start_offset).to eq(effort.start_offset_was + start_offset)
      expect(adjusted_times[1..-1]).to eq(unadjusted_times.map { |tfs| tfs - start_offset }[1..-1])
      response
    end
  end
end
