require "rails_helper"

RSpec.describe Interactors::UpdateEffortsStatus do
  subject { described_class.new(efforts_arg, times_container: times_container) }

  let(:efforts_arg) { efforts(:hardrock_2014_finished_first) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe "#initialize" do
    context "when a single effort is provided" do
      it "initializes without error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when multiple efforts are provided as an array" do
      let(:efforts_arg) { [efforts(:hardrock_2014_finished_first), efforts(:hardrock_2014_finished_with_stop)] }

      it "initializes without error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when efforts is nil" do
      let(:efforts_arg) { nil }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, /must include efforts/)
      end
    end
  end

  describe "#perform!" do
    let(:response) { described_class.perform!(efforts_arg, times_container: times_container) }
    let(:effort) { efforts(:hardrock_2014_finished_first) }
    let(:efforts_arg) { effort }
    let(:split_times) { effort.ordered_split_times }

    context "when effort statuses need updating" do
      before do
        effort.update(data_status: nil)
        split_times.each { |st| st.update(data_status: nil) }
      end

      it "persists data_status on efforts and split_times" do
        response

        expect(effort.reload.data_status).to eq("good")
        expect(split_times.map { |st| st.reload.data_status }).to all eq("good")
      end

      it "returns a successful response indicating what was updated" do
        expect(response).to be_successful
        expect(response.message).to include("effort").and include("split time")
      end
    end

    context "when effort statuses are already correct" do
      before do
        Interactors::SetEffortStatus.perform(effort, times_container: times_container)
        effort.save!
        split_times.each(&:save!)
      end

      it "returns an up-to-date message" do
        expect(response).to be_successful
        expect(response.message).to include("up to date")
      end
    end

    context "when multiple efforts are provided" do
      let(:effort_2) { efforts(:hardrock_2014_finished_with_stop) }
      let(:split_times_2) { effort_2.ordered_split_times }
      let(:efforts_arg) { [effort, effort_2] }

      before do
        effort.update(data_status: nil)
        split_times.each { |st| st.update(data_status: nil) }
        effort_2.update(data_status: nil)
        split_times_2.each { |st| st.update(data_status: nil) }
      end

      it "updates status for all provided efforts" do
        response

        expect(effort.reload.data_status).to eq("good")
        expect(effort_2.reload.data_status).to be_present
      end

      it "returns a message with pluralized counts" do
        expect(response).to be_successful
        expect(response.message).to include("2 efforts")
      end
    end

    context "when a split_time has bad data" do
      let(:split_time) { split_times.second }

      before do
        effort.update(data_status: nil)
        split_times.each { |st| st.update(data_status: nil) }
        split_time.update(absolute_time: split_time.absolute_time - 4.hours)
      end

      it "persists the bad status" do
        expect(response).to be_successful
        expect(effort.reload.data_status).to eq("bad")
        expect(split_time.reload.data_status).to eq("bad")
      end
    end
  end
end
