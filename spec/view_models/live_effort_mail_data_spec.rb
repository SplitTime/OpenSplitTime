# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LiveEffortMailData do
  subject { LiveEffortMailData.new(person: person, split_times: split_times) }
  let(:event) { events(:hardrock_2015) }
  let(:effort) { event.efforts.order(:bib_number).first }
  let(:person) { effort.person }
  let(:effort_split_times) { effort.split_times }
  let(:in_split_time) { effort_split_times[1] }
  let(:out_split_time) { effort_split_times[2] }
  let(:split_times) { [in_split_time, out_split_time] }

  describe '#initialize' do
    context 'with a person and split_times in an args hash' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'if no person or person_id is given' do
      let(:person) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include one of person or person_id/)
      end
    end
  end

  describe '#effort_data' do
    let(:expected_effort_data) { {full_name: effort.full_name,
                                  event_name: event.name,
                                  split_times_data: expected_split_times_data,
                                  effort_slug: effort.slug,
                                  event_slug: event.slug} }

    let(:expected_split_times_data) {
      [{split_name: expected_in_split_name,
        split_distance: expected_in_distance,
        absolute_time_local: in_split_time.absolute_time_local.strftime('%A, %B %-d, %Y %l:%M%p'),
        elapsed_time: TimeConversion.seconds_to_hms(in_split_time.time_from_start.to_i),
        pacer: in_split_time.pacer,
        stopped_here: in_split_time.stopped_here},
       {split_name: expected_out_split_name,
        split_distance: expected_out_distance,
        absolute_time_local: out_split_time.absolute_time_local.strftime('%A, %B %-d, %Y %l:%M%p'),
        elapsed_time: TimeConversion.seconds_to_hms(out_split_time.time_from_start.to_i),
        pacer: out_split_time.pacer,
        stopped_here: out_split_time.stopped_here}]
    }

    before { FactoryBot.reload }

    context 'when all split_times are in lap 1' do
      let(:expected_in_split_name) { in_split_time.split_name }
      let(:expected_out_split_name) { out_split_time.split_name }
      let(:expected_in_distance) { 67914 }
      let(:expected_out_distance) { 67914 }

      it 'returns a hash containing effort and split_time data' do
        expect(subject.effort_data).to eq(expected_effort_data)
      end
    end

    context 'when one or more split_times has a lap greater than 1' do
      let(:in_split_time) { effort_split_times[1] }
      let(:out_split_time) { effort_split_times[2] }
      before { out_split_time.lap = 2 }

      let(:expected_in_split_name) { in_split_time.split_name_with_lap }
      let(:expected_out_split_name) { out_split_time.split_name_with_lap }
      let(:expected_in_distance) { 67914 }
      let(:expected_out_distance) { 229653 }

      it 'uses split names with a lap indicator and adjusts distance as expected' do
        expect(subject.effort_data).to eq(expected_effort_data)
      end
    end
  end
end
