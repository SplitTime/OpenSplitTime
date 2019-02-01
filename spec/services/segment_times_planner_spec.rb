# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SegmentTimesPlanner do
  before { FactoryBot.reload }

  subject { SegmentTimesPlanner.new(expected_time: expected_time, event: event, time_points: time_points, similar_effort_ids: similar_effort_ids,
                                    start_time: start_time, times_container: times_container, serial_segments: serial_segments) }
  let(:expected_time) { 1000 }
  let(:event) { events(:hardrock_2016) }
  let(:time_points) { event.required_time_points.first(time_points_size) }
  let(:time_points_size) { 4 }
  let(:similar_effort_ids) { [1, 2, 3] }
  let(:start_time) { nil }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:serial_segments) { [] }

  describe '#initialize' do
    it 'initializes with expected_time, event, time_points, and similar_effort_ids in an args hash' do
      expect { subject }.not_to raise_error
    end

    context 'when no expected_time is given' do
      let(:expected_time) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include expected_time/)
      end
    end

    context 'when no event is given' do
      let(:event) { nil }
      let(:time_points) { [] }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'when no time_points are given' do
      let(:time_points) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include time_points/)
      end
    end

    context 'when no similar_effort_ids is given' do
      let(:similar_effort_ids) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include similar_effort_ids/)
      end
    end
  end

  describe '#times_from_start' do
    let(:segment_0_0) { Segment.new(begin_point: time_points[0], end_point: time_points[0]) }
    let(:segment_0_1) { Segment.new(begin_point: time_points[0], end_point: time_points[1]) }
    let(:segment_1_2) { Segment.new(begin_point: time_points[1], end_point: time_points[2]) }
    let(:segment_2_3) { Segment.new(begin_point: time_points[2], end_point: time_points[3]) }

    context 'when data is available for all serial segments' do
      let(:serial_segments) { [segment_0_0, segment_0_1, segment_1_2, segment_2_3] }

      before do
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_0)).and_return(0)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(1000)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(2000)
      end

      it 'returns a hash containing keys corresponding to the serial_segments' do
        expect(subject.times_from_start.size).to eq(time_points.size)
        expect(subject.times_from_start.keys).to eq(time_points)
      end

      context 'when expected_time equals total segment times' do
        let(:expected_time) { 3500 }

        it 'returns values corresponding to the expected times from start' do
          expected = [0, 1000, 1500, 3500]
          expect(subject.times_from_start.values).to eq(expected)
        end
      end

      context 'when expected_time does not equal total segment times' do
        let(:expected_time) { 4000 }

        it 'returns values adjusted to pace' do
          expected = [0, 1143, 1714, 4000]
          expect(subject.times_from_start.values).to eq(expected)
        end
      end

      context 'when round_to is zero' do
        let(:expected_time) { 4000 }
        let(:round_to) { 0 }

        it 'performs no rounding' do
          expected = [0, 1143, 1714, 4000]
          expect(subject.times_from_start(round_to: round_to).values).to eq(expected)
        end
      end

      context 'when round_to is 1.minute' do
        let(:expected_time) { 4000 }
        let(:round_to) { 1.minute }

        it 'rounds to the nearest minute' do
          expected = [0, 1140, 1740, 4020]
          expect(subject.times_from_start(round_to: round_to).values).to eq(expected)
        end
      end

      context 'when round_to is 10.minutes' do
        let(:expected_time) { 4000 }
        let(:round_to) { 10.minutes }

        it 'rounds to the nearest 10 minutes' do
          expected = [0, 1200, 1800, 4200]
          expect(subject.times_from_start(round_to: round_to).values).to eq(expected)
        end
      end

      context 'when round_to is 30.seconds' do
        let(:expected_time) { 4000 }
        let(:round_to) { 30.seconds }

        it 'rounds to the nearest 30 seconds' do
          expected = [0, 1140, 1710, 3990]
          expect(subject.times_from_start(round_to: round_to).values).to eq(expected)
        end
      end
    end

    context 'when no segments are available' do
      let(:serial_segments) { [] }

      it 'returns an empty hash' do
        expect(subject.times_from_start).to eq({})
      end
    end
  end

  describe '#absolute_times' do
    let(:segment_0_0) { Segment.new(begin_point: time_points[0], end_point: time_points[0]) }
    let(:segment_0_1) { Segment.new(begin_point: time_points[0], end_point: time_points[1]) }
    let(:segment_1_2) { Segment.new(begin_point: time_points[1], end_point: time_points[2]) }
    let(:segment_2_3) { Segment.new(begin_point: time_points[2], end_point: time_points[3]) }

    context 'when data is available for all serial segments' do
      let(:serial_segments) { [segment_0_0, segment_0_1, segment_1_2, segment_2_3] }

      before do
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_0)).and_return(0)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_0_1)).and_return(1000)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_1_2)).and_return(500)
        allow(times_container).to receive(:segment_time).with(a_segment_matching(segment_2_3)).and_return(2000)
      end

      it 'returns a hash containing keys corresponding to the serial_segments' do
        expect(subject.absolute_times.size).to eq(time_points.size)
        expect(subject.absolute_times.keys).to eq(time_points)
      end

      context 'when expected_time equals total segment times' do
        let(:expected_time) { 3500 }

        it 'returns values corresponding to the expected times from start' do
          expected = [0, 1000, 1500, 3500].map{ |seconds| event.start_time + seconds }
          expect(subject.absolute_times.values).to eq(expected)
        end
      end

      context 'when expected_time does not equal total segment times' do
        let(:expected_time) { 4000 }

        it 'returns values adjusted to pace' do
          expected = [0, 1143, 1714, 4000].map{ |seconds| event.start_time + seconds }
          expect(subject.absolute_times.values).to eq(expected)
        end
      end

      context 'when start_time is given' do
        let(:expected_time) { 4000 }
        let(:start_time) { Time.current }

        it 'returns values based on the given start_time' do
          expected = [0, 1143, 1714, 4000].map{ |seconds| start_time + seconds }
          expect(subject.absolute_times.values).to eq(expected)
        end
      end
    end

    context 'when no segments are available' do
      let(:serial_segments) { [] }

      it 'returns an empty hash' do
        expect(subject.absolute_times).to eq({})
      end
    end
  end
end
