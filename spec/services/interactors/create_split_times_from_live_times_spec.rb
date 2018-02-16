require 'rails_helper'

RSpec.describe Interactors::CreateSplitTimesFromLiveTimes do
  subject { Interactors::CreateSplitTimesFromLiveTimes.new(event: event, live_times: live_times) }
  let!(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
  let!(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }

  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  let(:effort) { create(:effort, event: event) }
  let(:event) { create(:event, course: course, event_group: event_group, start_time_in_home_zone: '2018-02-10 06:00:00') }
  let(:course) { create(:course) }
  let(:event_group) { create(:event_group, available_live: true) }
  let(:split_1) { create(:start_split, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:finish_split, course: course) }
  let(:splits) { [split_1, split_2, split_3, split_4] }

  let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
  let(:time_1) { time_zone.parse('2018-02-10 09:00:00') }
  let(:time_2) { time_zone.parse('2018-02-10 10:00:00') }

  let(:live_time_1) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_2, bitkey: out_bitkey, absolute_time: time_1) }
  let(:live_time_2) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_3, bitkey: in_bitkey, absolute_time: time_2) }
  let(:live_times) { [live_time_1, live_time_2] }

  before { event.splits << splits }
  before { allow(Interactors::UpdateEffortsStatus).to receive(:perform!).and_return(nil) }

  describe '#initialize' do
    context 'when event and live_times arguments are provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no event is provided' do
      subject { Interactors::CreateSplitTimesFromLiveTimes.new(event: nil, live_times: live_times) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'when no split_time_ids argument is provided' do
      subject { Interactors::CreateSplitTimesFromLiveTimes.new(event: event, live_times: nil) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include live_times/)
      end
    end
  end

  describe '#perform!' do
    context 'when live_times do not match existing split_times' do
      it 'creates new split_times from the given live_times' do
        expect(SplitTime.count).to eq(2)
        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)
        new_split_times = SplitTime.last(2)
        expect(new_split_times.map(&:sub_split)).to match_array(live_times.map(&:sub_split))
        expect(new_split_times.map(&:military_time)).to match_array(live_times.map { |lt| lt.military_time(event.home_time_zone) })
      end

      it 'updates the status of affected efforts' do
        subject.perform!
        expect(Interactors::UpdateEffortsStatus).to have_received(:perform!).with([effort])
      end

      context 'if the effort has an associated person' do
        let(:person) { create(:person) }
        before { effort.update(person: person) }

        it 'notifies followers' do
          expect { subject.perform! }.to have_enqueued_job.on_queue('default')
        end
      end
    end

    context 'when some live_times match existing split_times' do
      let(:live_times) { [live_time_1, live_time_2, matching_live_time] }
      let(:matching_live_time) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_1, bitkey: in_bitkey, absolute_time: matching_time) }
      let(:matching_time) { split_time_1.day_and_time }
      let(:unmatched_live_times) { live_times.first(2) }

      it 'creates new split_times for unmatched live_times only' do
        expect(SplitTime.count).to eq(2)
        response = subject.perform!
        expect(response).to be_successful
        expect(SplitTime.count).to eq(4)
        new_split_times = SplitTime.last(2)
        expect(new_split_times.map(&:sub_split)).to match_array(unmatched_live_times.map(&:sub_split))
        expect(new_split_times.map(&:military_time)).to match_array(unmatched_live_times.map { |lt| lt.military_time(event.home_time_zone) })
      end
    end
  end
end
