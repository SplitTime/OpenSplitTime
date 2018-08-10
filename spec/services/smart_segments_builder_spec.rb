# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmartSegmentsBuilder do
  subject { SmartSegmentsBuilder.new(event: event, laps: laps, expected_time: expected_time, similar_effort_ids: similar_effort_ids, times_container: times_container) }
  let(:event) { build_stubbed(:event_with_standard_splits, laps_required: 1, splits_count: 3) }
  let(:laps) { 1 }
  let(:expected_time) { 10_000 }
  let(:similar_effort_ids) { [1, 2, 3] }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :focused, effort_ids: similar_effort_ids) }

  describe '#initialize' do
    it 'initializes with an event, laps, expected_time, and similar_effort_ids in an args hash' do
      expect { subject }.not_to raise_error
    end

    context 'when event is nil' do
      let(:event) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'when laps is nil' do
      let(:laps) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include laps/)
      end
    end

    context 'when expected_time is nil' do
      let(:expected_time) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include expected_time/)
      end
    end

    context 'when similar_effort_ids is nil' do
      let(:similar_effort_ids) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/cannot be initialized with calc_model: :focused unless effort_ids are provided/)
      end
    end
  end

  describe '#segments' do
    let(:time_points) { event.time_points_through(laps) }
    let(:segment_0_0) { Segment.new(begin_point: time_points[0], end_point: time_points[0]) }
    let(:segment_0_1) { Segment.new(begin_point: time_points[0], end_point: time_points[1]) }
    let(:segment_1_2) { Segment.new(begin_point: time_points[1], end_point: time_points[2]) }
    let(:segment_2_3) { Segment.new(begin_point: time_points[2], end_point: time_points[3]) }
    let(:segment_1_3) { Segment.new(begin_point: time_points[1], end_point: time_points[3]) }

    before { allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_0)).and_return(0) }

    context 'for a single-lap event' do
      let(:event) { build_stubbed(:event_with_standard_splits, laps_required: 1, splits_count: 3) }

      context 'when data is available for all serial segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(6000)
        end

        it 'returns segments having begin time_points equal to the begin time_point plus all event time_points but the last' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1], time_points[2]])
        end

        it 'returns segments having end time_points equal to all event time_points' do
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[2], time_points[3]])
        end
      end

      context 'when data is not available for the second of three segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_3)).and_return(6000)
        end

        it 'returns segments as expected' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1]])
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[3]])
        end
      end

      context 'when data is not available for the last of three segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(nil)
        end

        it 'returns segments as expected' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1]])
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[2]])
        end
      end
    end

    context 'for a multi-lap event' do
      let(:event) { build_stubbed(:event_with_standard_splits, laps_required: 0, splits_count: 3) }
      let(:laps) { 2 }

      let(:segment_3_4) { Segment.new(begin_point: time_points[3], end_point: time_points[4]) }
      let(:segment_3_5) { Segment.new(begin_point: time_points[3], end_point: time_points[5]) }
      let(:segment_3_6) { Segment.new(begin_point: time_points[3], end_point: time_points[6]) }
      let(:segment_4_5) { Segment.new(begin_point: time_points[4], end_point: time_points[5]) }
      let(:segment_5_6) { Segment.new(begin_point: time_points[5], end_point: time_points[6]) }
      let(:segment_6_7) { Segment.new(begin_point: time_points[6], end_point: time_points[7]) }

      context 'when data is available for all serial segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(6000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_4)).and_return(600)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_4_5)).and_return(7000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_5_6)).and_return(700)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_6_7)).and_return(8000)
        end

        it 'returns segments having begin time_points equal to the begin time_point plus all event time_points but the last' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1], time_points[2], time_points[3], time_points[4], time_points[5], time_points[6]])
        end

        it 'returns segments having end time_points equal to all event time_points' do
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[2], time_points[3], time_points[4], time_points[5], time_points[6], time_points[7]])
        end
      end

      context 'when data is not available for three of many segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(6000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_4)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_4_5)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_5_6)).and_return(700)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_6_7)).and_return(8000)

          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_3)).and_return(5500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_5)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_6)).and_return(8300)
        end

        it 'returns segments as expected' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1], time_points[3], time_points[6]])
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[3], time_points[6], time_points[7]])
        end
      end
    end
  end
end
