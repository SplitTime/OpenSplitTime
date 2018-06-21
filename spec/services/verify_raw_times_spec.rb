require 'rails_helper'

RSpec.describe VerifyRawTimes do
  subject { VerifyRawTimes.new(raw_times: raw_times, effort: effort, event: event) }

  let(:event) { build_stubbed(:event, splits: splits, course: course, laps_required: 1) }
  let(:course) { build_stubbed(:course) }
  let(:effort) { build_stubbed(:effort, event: event, split_times: split_times, bib_number: 10) }
  let(:start_split) { build_stubbed(:start_split, course: course) }
  let(:cunningham_split) { build_stubbed(:split, course: course, base_name: 'Cunningham', distance_from_start: 10000) }
  let(:maggie_split) { build_stubbed(:split, course: course, base_name: 'Maggie', distance_from_start: 20000) }
  let(:splits) { [start_split, cunningham_split] }

  let(:split_time_1) { build_stubbed(:split_time, split: start_split, bitkey: 1, time_from_start: 0) }
  let(:split_time_2) { build_stubbed(:split_time, split: cunningham_split, bitkey: 1, time_from_start: 7200) }
  let(:split_time_3) { build_stubbed(:split_time, split: cunningham_split, bitkey: 64, time_from_start: 7300) }
  let(:split_time_4) { build_stubbed(:split_time, split: maggie_split, bitkey: 1, time_from_start: 15000) }
  let(:split_time_5) { build_stubbed(:split_time, split: maggie_split, bitkey: 64, time_from_start: 15100) }

  let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, effort: effort, lap: 1, bib_number: '10', split: start_split, split_name: 'start', bitkey: 1, stopped_here: false) }
  let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: 100, effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'cunningham', bitkey: 1, stopped_here: false) }
  let(:raw_time_3) { build_stubbed(:raw_time, event_group_id: 100, effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'cunningham', bitkey: 64, stopped_here: false) }

  describe '#perform' do
    context 'when all times exist on the effort' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_times) { [raw_time_2, raw_time_3] }

      it 'returns raw_times with existing_times_count attribute equal to 1' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        allow_any_instance_of(TimePredictor).to receive(:data_status).and_return(:good)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:existing_times_count)).to all be_nil

        resulting_raw_times = subject.perform
        expect(resulting_raw_times.size).to eq(2)
        expect(resulting_raw_times).to all be_a(RawTime)
        expect(resulting_raw_times.map(&:existing_times_count)).to eq([1, 1])

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when no times exist on the effort' do
      let(:split_times) { [split_time_1] }
      let(:raw_times) { [raw_time_2, raw_time_3] }

      it 'returns raw_times with existing_times_count attribute equal to 0' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        allow_any_instance_of(TimePredictor).to receive(:data_status).and_return(:good)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:existing_times_count)).to all be_nil

        resulting_raw_times = subject.perform
        expect(resulting_raw_times.size).to eq(2)
        expect(resulting_raw_times).to all be_a(RawTime)
        expect(resulting_raw_times.map(&:existing_times_count)).to eq([0, 0])

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when one time exists on the effort and one does not' do
      let(:split_times) { [split_time_1, split_time_3] }
      let(:raw_times) { [raw_time_2, raw_time_3] }

      it 'returns raw_times with existing_times_count attribute equal to expected values' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        allow_any_instance_of(TimePredictor).to receive(:data_status).and_return(:good)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:existing_times_count)).to all be_nil

        resulting_raw_times = subject.perform
        expect(resulting_raw_times.size).to eq(2)
        expect(resulting_raw_times).to all be_a(RawTime)
        expect(resulting_raw_times.map(&:existing_times_count)).to eq([0, 1])

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end
  end
end
