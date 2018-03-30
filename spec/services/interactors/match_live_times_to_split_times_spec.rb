require 'rails_helper'

RSpec.describe Interactors::MatchLiveTimesToSplitTimes do
  subject { Interactors::MatchLiveTimesToSplitTimes.new(event: event, live_times: live_times, tolerance: tolerance) }
  let(:tolerance) { nil }
  let!(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0) }
  let!(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 60.minutes) }
  let!(:split_time_3) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 70.minutes) }
  let(:split_times) { [split_time_1, split_time_2, split_time_3] }

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
  let(:time_1) { split_time_1.day_and_time }
  let(:time_2) { split_time_2.day_and_time }
  let(:time_3) { split_time_3.day_and_time }

  let(:live_time_1) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_time_1.split, bitkey: split_time_1.bitkey, absolute_time: time_1) }
  let(:live_time_2) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_time_2.split, bitkey: split_time_2.bitkey, absolute_time: time_2) }
  let(:live_time_3) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_time_3.split, bitkey: split_time_3.bitkey, absolute_time: time_3) }
  let(:live_time_4) { create(:live_time, bib_number: effort.bib_number, event: event, split: split_3, bitkey: in_bitkey, absolute_time: time_4) }
  let(:time_4) { event.start_time_in_home_zone + 3.hours }

  before { event.splits << splits }

  describe '#initialize' do
    let(:live_times) { [live_time_1, live_time_2, live_time_3] }

    context 'when event and live_times arguments are provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no event is provided' do
      subject { Interactors::MatchLiveTimesToSplitTimes.new(event: nil, live_times: live_times) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'when no split_time_ids argument is provided' do
      subject { Interactors::MatchLiveTimesToSplitTimes.new(event: event, live_times: nil) }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include live_times/)
      end
    end
  end

  describe '#perform!' do
    context 'when all live_times match existing split_times' do
      let(:matching_split_times) { split_times }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { live_times }
      let(:non_matching_live_times) { [] }

      it 'sets split_time of each live_time to the matching split_time' do
        verify_live_times
      end
    end

    context 'when some live_times match existing split_times' do
      let(:matching_split_times) { split_times }
      let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4] }
      let(:matching_live_times) { live_times.first(3) }
      let(:non_matching_live_times) { live_times.last(1) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when split and bitkey are the same and absolute_time is within tolerance' do
      let(:matching_split_times) { split_times }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { live_times }
      let(:non_matching_live_times) { [] }
      let(:tolerance) { 1.minute }

      before { live_time_2.update(absolute_time: split_time_2.day_and_time - 30.seconds) }

      it 'sets split_time for all live_times' do
        verify_live_times
      end
    end

    context 'when split and bitkey are the same and entered_time is within tolerance' do
      let(:matching_split_times) { split_times }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { live_times }
      let(:non_matching_live_times) { [] }
      let(:tolerance) { 1.minute }

      before { live_time_2.update(absolute_time: nil, entered_time: split_time_2.military_time) }

      it 'sets split_time for all live_times' do
        verify_live_times
      end
    end

    context 'when split and bitkey are the same but time is outside of tolerance' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }
      let(:tolerance) { 10.seconds }

      before { live_time_2.update(absolute_time: split_time_2.day_and_time - 30.seconds) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when split and bitkey are the same but entered_time is outside of tolerance' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }
      let(:tolerance) { 10.seconds }

      before { live_time_2.update(absolute_time: nil, entered_time: TimeConversion.absolute_to_hms(split_time_2.day_and_time - 30.seconds)) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when all attributes match but bib_number is different' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }

      before { live_time_2.update(bib_number: effort.bib_number + 1) }

      it 'sets split_time for all live_times' do
        verify_live_times
      end
    end

    context 'when bitkey and time are the same but split is different' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }

      before { live_time_2.update(split: split_1) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when split and time are the same but bitkey is different' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }

      before { live_time_2.update(bitkey: out_bitkey) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when split, bitkey, and time are the same but stopped_here is different' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }

      before { live_time_2.update(stopped_here: true) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when split, bitkey, and time are the same but pacer is different' do
      let(:matching_split_times) { [split_time_1, split_time_3] }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { [live_time_1, live_time_3] }
      let(:non_matching_live_times) { [live_time_2] }

      before { live_time_2.update(with_pacer: true) }

      it 'sets split_time for matching live_times only' do
        verify_live_times
      end
    end

    context 'when attributes are the same and split_time.pacer == nil but live_time.with_pacer == false' do
      let(:matching_split_times) { split_times }
      let(:live_times) { [live_time_1, live_time_2, live_time_3] }
      let(:matching_live_times) { live_times }
      let(:non_matching_live_times) { [] }

      before do
        split_time_2.update(pacer: nil)
        live_time_2.update(with_pacer: false)
      end

      it 'sets split_time for all live_times' do
        verify_live_times
      end
    end

    def verify_live_times
      expect(live_times.map(&:split_time_id)).to all be_nil
      response = subject.perform!
      expect(response).to be_successful
      expect(response.resources[:matched]).to match_array(matching_live_times)
      expect(response.resources[:unmatched]).to match_array(non_matching_live_times)
      expect(response.resources[:matched].map(&:split_time_id)).to match_array(matching_split_times.map(&:id))
      expect(response.resources[:unmatched].map(&:split_time_id)).to all be_nil
    end
  end
end
