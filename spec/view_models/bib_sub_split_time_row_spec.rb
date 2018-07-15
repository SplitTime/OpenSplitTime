require 'rails_helper'
include TimeZoneHelpers

RSpec.describe BibSubSplitTimeRow do
  subject { BibSubSplitTimeRow.new(bib_number: bib_number, effort: effort, time_records: time_records, split_times: split_times, event_group: event_group) }
  let(:bib_number) { '123' }
  let(:effort) { build_stubbed(:effort, event: event) }
  let(:event) { build_stubbed(:event, splits: [split]) }
  let(:split) { build_stubbed(:split) }
  let(:event_group) { build_stubbed(:event_group, events: [event]) }

  let(:time_records) { [live_time_1, live_time_2, live_time_3] }
  let(:live_time_1) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone(event, '2017-10-31 08:00:00'), source: source_1) }
  let(:live_time_2) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone(event, '2017-10-31 08:00:15'), source: source_2) }
  let(:live_time_3) { build_stubbed(:live_time, bib_number: '123', absolute_time: time_in_zone(event, '2017-10-31 09:00:00'), source: source_1) }

  let(:source_1) { 'ost-remote-abcd' }
  let(:source_2) { 'ost-remote-wxyz' }

  let(:source_text_1) { 'OSTR (abcd)' }
  let(:source_text_2) { 'OSTR (wxyz)' }

  let(:split_times) { [split_time_1, split_time_2] }
  let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split, data_status: 'good', time_from_start: live_time_1.absolute_time - event.start_time) }
  let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split, data_status: 'bad', time_from_start: live_time_2.absolute_time - event.start_time) }

  describe '#full_name' do
    it 'returns the full name of the effort provided' do
      expect(subject.full_name).to eq(effort.full_name)
    end
  end

  describe '#recorded_times' do
    it 'returns military times from all time_records grouped by source' do
      expected = {'OSTR (abcd)' => {military_times: %w(08:00:00 09:00:00), split_time_ids: [nil, nil]},
                  'OSTR (wxyz)' => {military_times: ['08:00:15'], split_time_ids: [nil]}}
      expect(subject.recorded_times).to eq(expected)
    end
  end

  describe '#result_times' do
    it 'returns lap, military time, and data status for each split time' do
      expected = [{lap: 1, military_time: '08:00:00', data_status: 'good', time_and_optional_lap: '08:00:00'},
                  {lap: 1, military_time: '08:00:15', data_status: 'bad', time_and_optional_lap: '08:00:15'}]
      expect(subject.result_times).to eq(expected)
    end
  end

  describe '#largest_discrepancy' do
    it 'returns the difference between the latest and earliest times' do
      expect(subject.largest_discrepancy).to eq(60.minutes)
    end

    context 'when times are on either side of midnight' do
      let(:live_time_1) { build_stubbed(:live_time, bib_number: '123', absolute_time: nil, entered_time: '23:50:00', source: source_1) }
      let(:live_time_2) { build_stubbed(:live_time, bib_number: '123', absolute_time: nil, entered_time: '00:20:00', source: source_2) }
      let(:live_time_3) { build_stubbed(:live_time, bib_number: '123', absolute_time: nil, entered_time: '00:10:00', source: source_1) }

      let(:split_times) { [] }

      it 'accounts for the rollover in day' do
        expect(subject.largest_discrepancy).to eq(30.minutes)
      end
    end
  end
end
