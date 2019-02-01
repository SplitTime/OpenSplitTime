# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmartSegmentsBuilder do
  subject { SmartSegmentsBuilder.new(event: event, time_points: time_points, times_container: times_container) }
  let(:event) { Event.new }
  let(:time_points) { [] }
  let(:laps) { 1 }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :focused, effort_ids: similar_effort_ids) }
  let(:similar_effort_ids) { [1, 2, 3] }

  describe '#initialize' do
    it 'initializes with an event, time_points, and a times_container in an args hash' do
      expect { subject }.not_to raise_error
    end

    context 'when event is nil' do
      let(:event) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'when time_points is nil' do
      let(:time_points) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include time_points/)
      end
    end

    context 'when times_container is nil' do
      let(:times_container) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include times_container/)
      end
    end
  end

  describe '#segments' do
    let(:segment_0_0) { Segment.new(begin_point: time_points[0], end_point: time_points[0]) }
    let(:segment_0_1) { Segment.new(begin_point: time_points[0], end_point: time_points[1]) }
    let(:segment_1_2) { Segment.new(begin_point: time_points[1], end_point: time_points[2]) }
    let(:segment_2_3) { Segment.new(begin_point: time_points[2], end_point: time_points[3]) }
    let(:segment_1_3) { Segment.new(begin_point: time_points[1], end_point: time_points[3]) }

    before { allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_0)).and_return(0) }

    context 'for a single-lap event' do
      let(:event) { events(:hardrock_2016) }
      let(:time_points) { event&.time_points_through(laps)&.first(4) }

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
      let(:event) { events(:rufa_2017_24h) }
      let(:laps) { 2 }
      let(:time_points) { event.time_points_through(laps) }

      let(:segment_3_4) { Segment.new(begin_point: time_points[3], end_point: time_points[4]) }
      let(:segment_3_5) { Segment.new(begin_point: time_points[3], end_point: time_points[5]) }
      let(:segment_3_6) { Segment.new(begin_point: time_points[3], end_point: time_points[6]) }
      let(:segment_4_5) { Segment.new(begin_point: time_points[4], end_point: time_points[5]) }

      context 'when data is available for all serial segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(6000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_4)).and_return(600)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_4_5)).and_return(7000)
        end

        it 'returns segments having begin time_points equal to the begin time_point plus all event time_points but the last' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0]] + time_points[0..-2])
        end

        it 'returns segments having end time_points equal to all event time_points' do
          expect(subject.segments.map(&:end_point)).to eq(time_points)
        end
      end

      context 'when data is not available for two of many segments' do
        before do
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(5000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(6000)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_4)).and_return(nil)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_4_5)).and_return(8000)

          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_3)).and_return(5500)
          allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_3_5)).and_return(8300)
        end

        it 'returns segments as expected' do
          expect(subject.segments.map(&:begin_point)).to eq([time_points[0], time_points[0], time_points[1], time_points[3]])
          expect(subject.segments.map(&:end_point)).to eq([time_points[0], time_points[1], time_points[3], time_points[5]])
        end
      end
    end
  end
end
