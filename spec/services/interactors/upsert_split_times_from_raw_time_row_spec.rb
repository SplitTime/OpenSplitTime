# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Interactors::UpsertSplitTimesFromRawTimeRow do
  subject { Interactors::UpsertSplitTimesFromRawTimeRow.new(event_group: event_group, raw_time_row: raw_time_row, times_container: times_container) }
  let(:event_group) { create(:event_group, available_live: true) }
  let(:raw_time_row) { RawTimeRow.new(raw_times, effort) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:effort) { effort }
  let(:start_time) { event.start_time }

  let!(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
  let!(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
  let!(:split_time_3) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
  let!(:split_time_4) { create(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, absolute_time: start_time + 20000, stopped_here: false) }

  let(:effort) { create(:effort, event: event) }
  let(:event) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 06:00:00') }
  let(:course) { create(:course) }
  let(:split_1) { create(:split, :start, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:split, :finish, course: course) }
  let(:splits) { [split_1, split_2, split_3, split_4] }

  let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
  let(:time_1) { time_zone.parse('2018-02-10 06:00:00') }
  let(:time_2) { time_zone.parse('2018-02-10 08:00:00') }
  let(:time_3) { time_zone.parse('2018-02-10 08:10:00') }
  let(:time_4) { time_zone.parse('2018-02-10 09:00:00') }
  let(:time_5) { time_zone.parse('2018-02-10 09:10:00') }

  let(:raw_time_1) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_1.base_name, bitkey: in_bitkey, absolute_time: time_1) }
  let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2) }
  let(:raw_time_3) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: out_bitkey, absolute_time: time_3) }
  let(:raw_time_4) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_3.base_name, bitkey: in_bitkey, absolute_time: time_4) }
  let(:raw_time_5) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_3.base_name, bitkey: out_bitkey, absolute_time: time_5) }

  let(:new_split_time_1) { SplitTime.new }
  let(:new_split_time_2) { SplitTime.new }

  before do
    event.splits << splits
    allow(Interactors::SetEffortStatus).to receive(:perform).and_return(Interactors::Response.new([], '', {}))
  end

  describe '#initialize' do
    let(:raw_times) { [raw_time_1, raw_time_2] }
    before do
      raw_time_1.new_split_time = new_split_time_1
      raw_time_2.new_split_time = new_split_time_2
    end

    context 'when event_group and raw_times arguments are provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no event_group is provided' do
      subject { Interactors::UpsertSplitTimesFromRawTimeRow.new(event_group: nil, raw_times: raw_times) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event_group/)
      end
    end

    context 'when no raw_times argument is provided' do
      subject { Interactors::UpsertSplitTimesFromRawTimeRow.new(event_group: event_group, raw_times: nil) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include raw_time_row/)
      end
    end
  end

  describe '#perform!' do
    context 'when the new_split_times are located at time_points occupied by existing split_times' do
      let(:raw_times) { [raw_time_2, raw_time_3] }
      let(:new_split_time_1) { SplitTime.new(absolute_time: start_time + 5000, effort_id: effort.id, lap: 1, split_id: split_2.id, bitkey: in_bitkey) }
      let(:new_split_time_2) { SplitTime.new(absolute_time: start_time + 5100, effort_id: effort.id, lap: 1, split_id: split_2.id, bitkey: out_bitkey) }
      before do
        raw_time_2.new_split_time = new_split_time_1
        raw_time_3.new_split_time = new_split_time_2
        effort.reload
      end

      it 'updates the existing split_times' do
        expect(SplitTime.count).to eq(4)
        expect(SplitTime.all.map(&:absolute_time)).to match_array([0, 10000, 11000, 20000].map { |e| start_time + e })

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)

        expect(SplitTime.all.map(&:absolute_time)).to match_array([0, 5000, 5100, 20000].map { |e| start_time + e })
      end

      it 'updates the status of affected efforts' do
        subject.perform!
        expect(Interactors::SetEffortStatus).to have_received(:perform).with(effort, times_container: times_container)
      end
    end

    context 'when the new_split_time is a start time' do
      let(:raw_times) { [raw_time_1] }
      let(:new_split_time_1) { SplitTime.new(absolute_time: start_time + 0, effort_id: effort.id, lap: 1, split_id: split_1.id, bitkey: in_bitkey) }
      before do
        raw_time_1.new_split_time = new_split_time_1
        effort.reload
      end

      it 'updates the offset and status of affected efforts' do
        subject.perform!
        expect(Interactors::SetEffortStatus).to have_received(:perform).with(effort, times_container: times_container)
      end
    end

    context 'when some new_split_times are located at time_points not occupied by existing split_times' do
      let(:raw_times) { [raw_time_4, raw_time_5] }
      let(:new_split_time_2) { SplitTime.new(absolute_time: start_time + 25000, effort_id: effort.id, lap: 1, split_id: split_3.id, bitkey: in_bitkey, pacer: true) }
      let(:new_split_time_3) { SplitTime.new(absolute_time: start_time + 26000, effort_id: effort.id, lap: 1, split_id: split_3.id, bitkey: out_bitkey, pacer: true) }
      before do
        raw_time_4.new_split_time = new_split_time_2
        raw_time_5.new_split_time = new_split_time_3
        effort.reload
      end

      it 'updates existing split_times for occupied time_points and creates new split_times for unoccupied time_points' do
        expect(SplitTime.count).to eq(4)
        expect(SplitTime.all.map(&:absolute_time)).to match_array([0, 10000, 11000, 20000].map { |e| start_time + e })
        expect(SplitTime.all.map(&:pacer)).to match_array([nil, nil, nil, nil])

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(5)

        expect(SplitTime.all.map(&:absolute_time)).to match_array([0, 10000, 11000, 25000, 26000].map { |e| start_time + e })
        expect(SplitTime.all.map(&:pacer)).to match_array([nil, nil, nil, true, true])
      end
    end
  end
end
