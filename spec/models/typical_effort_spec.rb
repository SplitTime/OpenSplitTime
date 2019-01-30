# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypicalEffort, type: :model do
  subject { TypicalEffort.new(event: event, expected_time_from_start: expected_time_from_start, start_time: start_time,
                              time_points: time_points, expected_time_point: expected_time_point) }
  let(:event) { events(:hardrock_2016) }
  let(:expected_time_from_start) { 1.hour }
  let(:start_time) { event.start_time }
  let(:time_points) { event.required_time_points }
  let(:expected_time_point) { nil }

  describe '#initialize' do
    context 'when given an event, expected_time_from_start, start_time, and time_points' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#ordered_split_times' do
    before do
      allow(subject.similar_effort_finder).to receive(:effort_ids).and_return([1, 2, 3])
      allow(subject.send(:times_planner)).to receive(:absolute_times).and_return(absolute_times)
    end

    context 'when plan_times are available for all time_points' do
      let(:absolute_times) { time_points.map.with_index { |tp, i| [tp, start_time + (i * 1000)] }.to_h }

      it 'creates split_times for each time_point using the provided plan_times' do
        expect(subject.ordered_split_times.size).to eq(time_points.size)
        expect(subject.ordered_split_times).to all be_a(SplitTime)
        expect(subject.ordered_split_times.map(&:time_point)).to eq(time_points)
        expect(subject.ordered_split_times.map(&:absolute_time)).to eq(absolute_times.values)
      end
    end

    context 'when plan_times are available for less than all time_points' do
      let(:available_time_points) { time_points.values_at(0, 1, -1) }
      let(:absolute_times) { available_time_points.map.with_index { |tp, i| [tp, start_time + (i * 1000)] }.to_h }

      it 'creates split_times for only those time_points that return plan_times' do
        expect(subject.ordered_split_times.size).to eq(available_time_points.size)
        expect(subject.ordered_split_times).to all be_a(SplitTime)
        expect(subject.ordered_split_times.map(&:time_point)).to eq(available_time_points)
        expect(subject.ordered_split_times.map(&:absolute_time)).to eq(absolute_times.values)
      end
    end
  end
end
