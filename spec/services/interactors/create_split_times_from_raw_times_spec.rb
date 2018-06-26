require 'rails_helper'

RSpec.describe Interactors::CreateSplitTimesFromRawTimes do
  subject { Interactors::CreateSplitTimesFromRawTimes.new(event_group: event_group, raw_times: raw_times) }
  let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
  let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  let(:effort_1) { create(:effort, event: event_1) }
  let(:event_1) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 06:00:00') }
  let(:event_2) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 07:00:00') }
  let(:course) { create(:course) }
  let(:event_group) { create(:event_group, available_live: true) }
  let(:split_1) { create(:start_split, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:finish_split, course: course) }
  let(:splits) { [split_1, split_2, split_3, split_4] }

  let(:time_zone) { ActiveSupport::TimeZone[event_1.home_time_zone] }
  let(:time_1) { time_zone.parse('2018-02-10 09:00:00') }
  let(:time_2) { time_zone.parse('2018-02-10 10:00:00') }

  let(:raw_time_1) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: out_bitkey, absolute_time: time_1) }
  let(:raw_time_2) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split_name: split_3.base_name, bitkey: in_bitkey, absolute_time: time_2) }
  let(:raw_times) { [raw_time_1, raw_time_2] }

  before do
    event_1.splits << splits
    event_2.splits << splits
    allow(Interactors::UpdateEffortsStatus).to receive(:perform!).and_return(nil)
  end

  describe '#initialize' do
    context 'when event_group and raw_times arguments are provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no event_group is provided' do
      subject { Interactors::CreateSplitTimesFromRawTimes.new(event_group: nil, raw_times: raw_times) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event_group/)
      end
    end

    context 'when no split_time_ids argument is provided' do
      subject { Interactors::CreateSplitTimesFromRawTimes.new(event_group: event_group, raw_times: nil) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include raw_times/)
      end
    end
  end

  describe '#perform!' do
    context 'when raw_times do not match existing split_times' do
      it 'creates new split_times from the given raw_times' do
        expect(SplitTime.count).to eq(2)

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)

        new_split_times = SplitTime.last(2)
        expect(new_split_times.map(&:sub_split)).to match_array(raw_times.map(&:sub_split))
        expect(new_split_times.map(&:military_time)).to match_array(raw_times.map { |lt| lt.military_time(event_1.home_time_zone) })
      end

      it 'updates the status of affected efforts' do
        subject.perform!
        expect(Interactors::UpdateEffortsStatus).to have_received(:perform!).with([effort_1])
      end

      context 'if the effort has an associated person' do
        let(:person) { create(:person) }
        before { effort_1.update(person: person) }

        it 'notifies followers' do
          expect { subject.perform! }.to have_enqueued_job.on_queue('default')
        end
      end
    end

    context 'when some raw_times match existing split_times' do
      let(:raw_times) { [raw_time_1, raw_time_2, matching_raw_time] }
      let(:matching_raw_time) { create(:raw_time, bib_number: effort_1.bib_number, event_group: event_group, split: split_1, bitkey: in_bitkey, absolute_time: matching_time) }
      let(:matching_time) { split_time_1.day_and_time }
      let(:unmatched_raw_times) { raw_times.first(2) }

      it 'creates new split_times for unmatched raw_times only' do
        expect(SplitTime.count).to eq(2)

        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)

        new_split_times = SplitTime.last(2)
        expect(new_split_times.map(&:split_id)).to match_array([split_2.id, split_3.id])
        expect(new_split_times.map(&:sub_split)).to match_array(unmatched_raw_times.map(&:sub_split))
        expect(new_split_times.map(&:military_time)).to match_array(unmatched_raw_times.map { |rt| rt.military_time(event_1.home_time_zone) })
      end
    end
  end
end
