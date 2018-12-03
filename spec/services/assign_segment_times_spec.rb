# frozen_string_literal: true

RSpec.describe AssignSegmentTimes do
  describe '.perform' do
    subject { AssignSegmentTimes.perform(ordered_split_times, source_attribute) }
    let(:source_attribute) { :absolute_time }

    context 'when split_times each have an absolute_time in expected order' do
      let(:ordered_split_times) { [st1, st2, st3] }
      let(:st1) { SplitTime.new(absolute_time: '2018-11-30 06:00:00') }
      let(:st2) { SplitTime.new(absolute_time: '2018-11-30 06:30:00') }
      let(:st3) { SplitTime.new(absolute_time: '2018-11-30 06:45:00') }

      it 'sets segment_times on all but the first' do
        expect(ordered_split_times.map(&:segment_time)).to all be_nil
        expect(subject.map(&:segment_time)).to eq([nil, 30.minutes, 15.minutes])
      end
    end

    context 'when split_times each have an absolute_time in unexpected order' do
      let(:ordered_split_times) { [st1, st2, st3] }
      let(:st1) { SplitTime.new(absolute_time: '2018-11-30 06:00:00') }
      let(:st2) { SplitTime.new(absolute_time: '2018-11-30 06:30:00') }
      let(:st3) { SplitTime.new(absolute_time: '2018-11-30 06:15:00') }

      it 'uses negative segment_times' do
        expect(ordered_split_times.map(&:segment_time)).to all be_nil
        expect(subject.map(&:segment_time)).to eq([nil, 30.minutes, -15.minutes])
      end
    end

    context 'when some split_times have no absolute_time' do
      let(:ordered_split_times) { [st1, st2, st3] }
      let(:st1) { SplitTime.new(absolute_time: '2018-11-30 06:00:00') }
      let(:st2) { SplitTime.new(absolute_time: '2018-11-30 06:30:00') }
      let(:st3) { SplitTime.new(absolute_time: nil) }

      it 'calculates segment times where possible' do
        expect(ordered_split_times.map(&:segment_time)).to all be_nil
        expect(subject.map(&:segment_time)).to eq([nil, 30.minutes, nil])
      end
    end
  end
end
