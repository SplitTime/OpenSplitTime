require 'rails_helper'

RSpec.describe Interactors::AdjustEffortOffset do
  subject { Interactors::AdjustEffortOffset.new(effort) }
  before { FactoryGirl.reload }
  let(:split_times) { build_stubbed_list(:split_times_hardrock_45, 4) }
  let(:effort) { build_stubbed(:effort) }

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
    before { allow(effort).to receive(:split_times).and_return(split_times) }
    before { expect(effort.start_offset).to eq(0) }

    context 'when start_offset has been changed to a positive value' do
      before { effort.start_offset = 100 }

      it 'adjusts all times_from_start (other than the start split_time) by the negative of the change in start_offset' do
        validate_adjustments
      end
    end

    context 'when start_offset has been changed to a negative value' do
      before { effort.start_offset = -100 }

      it 'functions properly' do
        validate_adjustments
      end
    end

    context 'when start_offset is not adjusted' do
      before { effort.start_offset = 0 }

      it 'functions properly when start_offset is not adjusted' do
        validate_adjustments
      end
    end

    context 'when the effort has no split_times' do
      before { allow(effort).to receive(:split_times).and_return([]) }

      it 'does not fail' do
        validate_adjustments
      end
    end

    def validate_adjustments
      start_offset = effort.start_offset
      unadjusted_times = effort.ordered_split_times.map(&:time_from_start)
      subject.perform!
      adjusted_times = effort.ordered_split_times.map(&:time_from_start)
      expect(adjusted_times[0]).to eq(unadjusted_times[0])
      expect(adjusted_times[1..-1]).to eq(unadjusted_times.map { |tfs| tfs - start_offset }[1..-1])
    end
  end
end
