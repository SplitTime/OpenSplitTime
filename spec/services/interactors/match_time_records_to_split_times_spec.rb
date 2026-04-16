require "rails_helper"

RSpec.describe Interactors::MatchTimeRecordsToSplitTimes do
  include BitkeyDefinitions

  subject { described_class.new(time_records: time_records, split_times: split_times, tolerance: tolerance) }

  let(:tolerance) { 1.minute }
  let(:event_group) { event_groups(:hardrock_2014) }
  let(:event) { events(:hardrock_2014) }
  let(:effort) { efforts(:hardrock_2014_not_started) }
  let(:split_1) { splits(:hardrock_cw_start) }
  let(:split_2) { splits(:hardrock_cw_telluride) }

  let!(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0) }
  let!(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 60.minutes) }
  let(:split_times) { SplitTime.where(id: [split_time_1.id, split_time_2.id]).with_time_record_matchers }

  let(:time_1) { split_time_1.absolute_time_local }
  let(:time_2) { split_time_2.absolute_time_local }

  let(:raw_time_1) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_1.base_name, bitkey: in_bitkey, absolute_time: time_1) }
  let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2) }
  let(:time_records) { RawTime.where(id: [raw_time_1.id, raw_time_2.id]).with_relation_ids }

  describe "#initialize" do
    context "when all required arguments are provided" do
      it "initializes without error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when time_records is missing" do
      it "raises an ArgumentError" do
        expect { described_class.new(split_times: split_times) }.to raise_error(ArgumentError)
      end
    end

    context "when split_times is missing" do
      it "raises an ArgumentError" do
        expect { described_class.new(time_records: time_records) }.to raise_error(ArgumentError)
      end
    end

    context "when tolerance is nil" do
      let(:tolerance) { nil }

      it "defaults tolerance to 1 minute" do
        response = subject.perform!
        expect(response).to be_successful
        expect(response.resources[:matched].size).to eq(2)
      end
    end
  end

  describe "#perform!" do
    let(:response) { subject.perform! }

    context "when all time records match split times" do
      it "matches all records" do
        expect(response).to be_successful
        expect(response.resources[:matched].size).to eq(2)
        expect(response.resources[:unmatched]).to be_empty
      end
    end

    context "when absolute_time is within tolerance" do
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2 - 30.seconds) }

      it "matches the record" do
        expect(response).to be_successful
        expect(response.resources[:matched].size).to eq(2)
      end
    end

    context "when absolute_time is outside tolerance" do
      let(:tolerance) { 10.seconds }
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2 - 30.seconds) }

      it "does not match the record" do
        expect(response.resources[:matched].size).to eq(1)
        expect(response.resources[:unmatched].size).to eq(1)
      end
    end

    context "when time_record has nil absolute_time but matching entered_time" do
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: nil, entered_time: split_time_2.military_time) }

      it "matches using entered_time" do
        expect(response).to be_successful
        expect(response.resources[:matched].size).to eq(2)
      end
    end

    context "when bib_number does not match" do
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number + 1, event_group: event_group, split_name: split_2.base_name, bitkey: in_bitkey, absolute_time: time_2) }

      it "does not match the record" do
        expect(response.resources[:matched].size).to eq(1)
        expect(response.resources[:unmatched].size).to eq(1)
      end
    end

    context "when split_id does not match" do
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_1.base_name, bitkey: in_bitkey, absolute_time: time_2) }

      it "does not match the record" do
        expect(response.resources[:matched].size).to eq(1)
        expect(response.resources[:unmatched].size).to eq(1)
      end
    end

    context "when bitkey does not match" do
      let(:raw_time_2) { create(:raw_time, bib_number: effort.bib_number, event_group: event_group, split_name: split_2.base_name, bitkey: out_bitkey, absolute_time: time_2) }

      it "does not match the record" do
        expect(response.resources[:matched].size).to eq(1)
        expect(response.resources[:unmatched].size).to eq(1)
      end
    end

    context "when the time record is already matched" do
      before { raw_time_2.update(split_time: split_time_2) }

      it "does not re-match the record" do
        expect(response.resources[:matched].size).to eq(1)
        expect(response.resources[:unmatched].size).to eq(1)
      end
    end

    context "when the candidate pool contains a matching split_time belonging to a different effort" do
      let(:other_event_group) { create(:event_group) }
      let(:other_event) do
        create(:event, event_group: other_event_group, course: event.course,
                       scheduled_start_time: event.scheduled_start_time)
      end
      let(:other_effort) do
        create(:effort, event: other_event, bib_number: effort.bib_number,
                        scheduled_start_time: effort.scheduled_start_time)
      end
      let!(:other_split_time) do
        create(:split_time, effort: other_effort, lap: 1, split: split_1, bitkey: in_bitkey,
                            absolute_time: split_time_1.absolute_time)
      end
      let(:split_times) do
        SplitTime.where(id: [split_time_2.id, other_split_time.id]).with_time_record_matchers
      end

      it "does not match a split_time that belongs to a different effort" do
        expect(response).to be_successful
        expect(response.resources[:matched].map(&:id)).to contain_exactly(raw_time_2.id)
        expect(response.resources[:unmatched].map(&:id)).to contain_exactly(raw_time_1.id)
        expect(response.resources[:matched].map(&:split_time_id)).not_to include(other_split_time.id)
      end
    end
  end
end
