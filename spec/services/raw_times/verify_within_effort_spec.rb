# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::RawTimes::VerifyWithinEffort do
  subject { described_class.new(subject_raw_times, effort) }
  let(:subject_raw_times) { [raw_time] }
  let(:effort) { event_group.efforts.find_by(bib_number: bib_number) }

  let(:event_group) { event_groups(:hardrock_2015) }
  let(:event) { effort.event }
  let(:split) { event.splits.find_by(base_name: split_name) }
  let(:bib_number) { '171' }

  let(:raw_time) do
    build(:raw_time,
          event_group: event_group,
          effort: effort,
          lap: lap,
          split: split,
          bitkey: bitkey,
          absolute_time_local: absolute_time_local,
          with_pacer: with_pacer,
          stopped_here: stopped_here)
  end

  let(:lap) { 1 }
  let(:absolute_time) { nil }
  let(:with_pacer) { false }
  let(:stopped_here) { false }

  describe '#perform' do
    let(:verify_raw_times) { subject.perform }
    context 'for a single raw time' do
      context 'when no existing time is present' do
        let(:split_name) { 'Putnam' }
        let(:bitkey) { in_bitkey }

        expected_results = [
          {time: '2015-07-12 02:30:00', status: 'good'},
          {time: '2015-07-11 20:30:00', status: 'questionable'},
          {time: '2015-07-11 16:30:00', status: 'bad'},
        ]

        expected_results.each do |row|
          context "when the time is #{row[:time]}" do
            let(:absolute_time_local) { row[:time] }
            it 'sets attributes as expected' do
              verify_raw_times
              expect(raw_time.split_time_exists).to eq(false)
              expect(raw_time.data_status).to eq(row[:status])
            end
          end
        end
      end

      context 'when an existing time is present' do
        let(:split_name) { 'Grouse' }
        let(:bitkey) { in_bitkey }

        expected_results = [
          {time: '2015-07-10 23:00:00', status: 'good'},
          {time: '2015-07-10 20:00:00', status: 'questionable'},
          {time: '2015-07-10 18:00:00', status: 'bad'},
        ]

        expected_results.each do |row|
          context "when the time is #{row[:time]}" do
            let(:absolute_time_local) { row[:time] }
            it 'sets attributes as expected' do
              verify_raw_times
              expect(raw_time.split_time_exists).to eq(true)
              expect(raw_time.data_status).to eq(row[:status])
            end
          end
        end
      end
    end

    context 'for in and out raw times' do
      let(:subject_raw_times) { [in_raw_time, out_raw_time] }

      let(:in_raw_time) do
        build(:raw_time,
              event_group: event_group,
              effort: effort,
              lap: lap,
              split: split,
              bitkey: in_bitkey,
              absolute_time_local: absolute_time_local_in,
              with_pacer: with_pacer,
              stopped_here: stopped_here)
      end

      let(:out_raw_time) do
        build(:raw_time,
              event_group: event_group,
              effort: effort,
              lap: lap,
              split: split,
              bitkey: out_bitkey,
              absolute_time_local: absolute_time_local_out,
              with_pacer: with_pacer,
              stopped_here: stopped_here)
      end

      let(:split_name) { 'Putnam' }

      expected_results = [
        {in_time: '2015-07-12 02:30:00', out_time: '2015-07-12 02:40:00', in_status: 'good', out_status: 'good'},
        {in_time: '2015-07-12 02:30:00', out_time: '2015-07-12 02:20:00', in_status: 'good', out_status: 'bad'},
        {in_time: '2015-07-11 20:30:00', out_time: '2015-07-11 20:40:00', in_status: 'questionable', out_status: 'questionable'},
        {in_time: '2015-07-11 20:30:00', out_time: '2015-07-12 02:40:00', in_status: 'questionable', out_status: 'good'},
        {in_time: '2015-07-11 16:30:00', out_time: '2015-07-11 16:40:00', in_status: 'bad', out_status: 'bad'},
        {in_time: '2015-07-11 16:30:00', out_time: '2015-07-12 02:40:00', in_status: 'bad', out_status: 'good'},
      ]

      expected_results.each do |row|
        context "when the in time is #{row[:in_time]} and the out time is #{row[:out_time]}" do
          let(:absolute_time_local_in) { row[:in_time] }
          let(:absolute_time_local_out) { row[:out_time] }
          it 'sets attributes as expected' do
            verify_raw_times
            expect(in_raw_time.split_time_exists).to eq(false)
            expect(out_raw_time.split_time_exists).to eq(false)
            expect(in_raw_time.data_status).to eq(row[:in_status])
            expect(out_raw_time.data_status).to eq(row[:out_status])
          end
        end
      end
    end
  end
end
