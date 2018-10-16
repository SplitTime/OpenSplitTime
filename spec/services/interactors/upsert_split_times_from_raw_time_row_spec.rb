require 'rails_helper'

RSpec.describe Interactors::UpsertSplitTimesFromRawTimeRow do
  subject { Interactors::UpsertSplitTimesFromRawTimeRow.new(event_group: event_group, raw_time_row: raw_time_row, times_container: times_container) }
  let(:event_group) { create(:event_group, available_live: true) }
  let(:raw_time_row) { RawTimeRow.new(raw_times, effort) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:effort) { effort_1 }

  let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
  let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
  let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
  let!(:split_time_4) { create(:split_time, effort: effort_1, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: false) }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  let(:effort_1) { create(:effort, event: event_1) }
  let(:event_1) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 06:00:00') }
  let(:event_2) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 07:00:00') }
  let(:course) { create(:course) }
  let(:split_1) { create(:split, :start, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:split, :finish, course: course) }
  let(:splits) { [split_1, split_2, split_3, split_4] }

  let(:time_zone) { ActiveSupport::TimeZone[event_1.home_time_zone] }
  let(:time_1) { time_zone.parse('2018-02-10 06:00:00') }
  let(:time_2) { time_zone.parse('2018-02-10 08:00:00') }
  let(:time_3) { time_zone.parse('2018-02-10 08:10:00') }
  let(:time_4) { time_zone.parse('2018-02-10 09:00:00') }
  let(:time_5) { time_zone.parse('2018-02-10 09:10:00') }

  let(:raw_time_1) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_1.base_name, bitkey: in_bitkey, absolute_time: time_1) }
  let(:raw_time_2) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2) }
  let(:raw_time_3) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: out_bitkey, absolute_time: time_3) }
  let(:raw_time_4) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_3.base_name, bitkey: in_bitkey, absolute_time: time_4) }
  let(:raw_time_5) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_3.base_name, bitkey: out_bitkey, absolute_time: time_5) }

  let(:new_split_time_1) { SplitTime.new }
  let(:new_split_time_2) { SplitTime.new }

  before do
    event_1.splits << splits
    event_2.splits << splits
    allow(Interactors::AdjustEffortOffset).to receive(:perform).and_return(Interactors::Response.new([], '', {}))
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
      let(:new_split_time_1) { SplitTime.new(time_from_start: 5000, effort_id: effort_1.id, lap: 1, split_id: split_2.id, bitkey: in_bitkey) }
      let(:new_split_time_2) { SplitTime.new(time_from_start: 5100, effort_id: effort_1.id, lap: 1, split_id: split_2.id, bitkey: out_bitkey) }
      before do
        raw_time_2.new_split_time = new_split_time_1
        raw_time_3.new_split_time = new_split_time_2
      end

      it 'updates the existing split_times' do
        expect(SplitTime.count).to eq(4)
        expect(SplitTime.all.map(&:time_from_start)).to match_array([0, 10000, 11000, 20000])

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)

        expect(SplitTime.all.map(&:time_from_start)).to match_array([0, 5000, 5100, 20000])
      end

      it 'updates the status of affected efforts but does not attempt to adjust the offset' do
        subject.perform!
        expect(Interactors::AdjustEffortOffset).not_to have_received(:perform).with(effort_1)
        expect(Interactors::SetEffortStatus).to have_received(:perform).with(effort_1, times_container: times_container)
      end
    end

    context 'when the new_split_time is a start time' do
      let(:raw_times) { [raw_time_1] }
      let(:new_split_time_1) { SplitTime.new(time_from_start: 0, effort_id: effort_1.id, lap: 1, split_id: split_1.id, bitkey: in_bitkey) }
      before do
        raw_time_1.new_split_time = new_split_time_1
      end

      it 'updates the offset and status of affected efforts' do
        subject.perform!
        expect(Interactors::AdjustEffortOffset).to have_received(:perform).with(effort_1)
        expect(Interactors::SetEffortStatus).to have_received(:perform).with(effort_1, times_container: times_container)
      end
    end

    context 'when some new_split_times are located at time_points not occupied by existing split_times' do
      let(:raw_times) { [raw_time_4, raw_time_5] }
      let(:new_split_time_2) { SplitTime.new(time_from_start: 25000, effort_id: effort_1.id, lap: 1, split_id: split_3.id, bitkey: in_bitkey, pacer: true) }
      let(:new_split_time_3) { SplitTime.new(time_from_start: 26000, effort_id: effort_1.id, lap: 1, split_id: split_3.id, bitkey: out_bitkey, pacer: true) }
      before do
        raw_time_4.new_split_time = new_split_time_2
        raw_time_5.new_split_time = new_split_time_3
      end

      it 'updates existing split_times for occupied time_points and creates new split_times for unoccupied time_points' do
        expect(SplitTime.count).to eq(4)
        expect(SplitTime.all.map(&:time_from_start)).to match_array([0, 10000, 11000, 20000])
        expect(SplitTime.all.map(&:pacer)).to match_array([nil, nil, nil, nil])

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(5)

        expect(SplitTime.all.map(&:time_from_start)).to match_array([0, 10000, 11000, 25000, 26000])
        expect(SplitTime.all.map(&:pacer)).to match_array([nil, nil, nil, true, true])
      end
    end
  end
end
