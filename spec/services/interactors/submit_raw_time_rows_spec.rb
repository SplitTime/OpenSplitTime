require "rails_helper"

RSpec.describe Interactors::SubmitRawTimeRows do
  include BitkeyDefinitions

  let(:event_group) { event_groups(:hardrock_2014) }
  let(:event) { events(:hardrock_2014) }
  let(:effort) { efforts(:hardrock_2014_not_started) }
  let(:split_1) { splits(:hardrock_cw_start) }
  let(:upsert_response) { Interactors::Response.new([], "", { upserted_split_times: [] }) }

  before do
    allow(EnrichRawTimeRow).to receive(:perform)
    allow(Interactors::UpsertSplitTimesFromRawTimeRow).to receive(:perform!).and_return(upsert_response)
  end

  describe "#initialize" do
    context "when all required arguments are provided" do
      it "initializes without error" do
        expect do
          described_class.new(raw_time_rows: [], event_group: event_group, force_submit: false, mark_as_reviewed: false)
        end.not_to raise_error
      end
    end

    context "when raw_time_rows is missing" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(raw_time_rows: nil, event_group: event_group, force_submit: false, mark_as_reviewed: false)
        end.to raise_error(ArgumentError, /must include raw_time_rows/)
      end
    end

    context "when event_group is missing" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(raw_time_rows: [], event_group: nil, force_submit: false, mark_as_reviewed: false)
        end.to raise_error(ArgumentError, /must include event_group/)
      end
    end

    context "when force_submit is nil" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(raw_time_rows: [], event_group: event_group, force_submit: nil, mark_as_reviewed: false)
        end.to raise_error(ArgumentError, /must include force_submit/)
      end
    end

    context "when mark_as_reviewed is nil" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(raw_time_rows: [], event_group: event_group, force_submit: false, mark_as_reviewed: nil)
        end.to raise_error(ArgumentError, /must include mark_as_reviewed/)
      end
    end
  end

  describe "#perform!" do
    let(:raw_time) do
      build(:raw_time, event_group: event_group, bib_number: effort.bib_number.to_s,
                       split_name: split_1.base_name, bitkey: in_bitkey)
    end
    let(:raw_time_row) { RawTimeRow.new([raw_time], nil, nil, nil, []) }
    let(:force_submit) { true }
    let(:mark_as_reviewed) { false }
    let(:current_user_id) { nil }

    let(:response) do
      described_class.perform!(
        raw_time_rows: [raw_time_row],
        event_group: event_group,
        force_submit: force_submit,
        mark_as_reviewed: mark_as_reviewed,
        current_user_id: current_user_id,
      )
    end

    context "when raw_times are valid" do
      it "saves raw_times to the database" do
        expect { response }.to change(RawTime, :count).by(1)
      end

      it "sets event_group_id on saved raw_times" do
        response
        expect(raw_time.reload.event_group_id).to eq(event_group.id)
      end

      it "looks up the effort by bib_number" do
        response
        expect(raw_time_row.effort).to eq(effort)
      end

      it "returns a successful response with no problem rows" do
        expect(response).to be_successful
        expect(response.resources[:problem_rows]).to be_empty
      end
    end

    context "when mark_as_reviewed is true" do
      let(:mark_as_reviewed) { true }
      let(:current_user_id) { 1 }

      it "sets reviewed_by and reviewed_at on saved raw_times" do
        response
        raw_time.reload
        expect(raw_time.reviewed_by).to eq(current_user_id)
        expect(raw_time.reviewed_at).to be_present
      end
    end

    context "when the raw_time is not clean and force_submit is false" do
      let(:force_submit) { false }

      before do
        allow(EnrichRawTimeRow).to receive(:perform) do |args|
          args[:raw_time_row].raw_times.each { |rt| rt.data_status = :bad }
        end
      end

      it "does not save the raw_time" do
        expect { response }.not_to change(RawTime, :count)
      end

      it "includes the row in problem_rows" do
        expect(response.resources[:problem_rows]).to include(raw_time_row)
      end
    end

    context "when force_submit is true and the raw_time is not clean" do
      let(:force_submit) { true }

      before do
        allow(EnrichRawTimeRow).to receive(:perform) do |args|
          args[:raw_time_row].raw_times.each { |rt| rt.data_status = :bad }
        end
      end

      it "saves the raw_time anyway" do
        expect { response }.to change(RawTime, :count).by(1)
      end

      it "returns no problem rows" do
        expect(response.resources[:problem_rows]).to be_empty
      end
    end

    context "when the bib_number does not match any effort" do
      let(:raw_time) do
        build(:raw_time, event_group: event_group, bib_number: "99999",
                         split_name: split_1.base_name, bitkey: in_bitkey)
      end

      before do
        allow(VerifyRawTimeRow).to receive(:perform) do |rtr, **_|
          rtr.errors << { title: "missing effort" }
        end
      end

      it "does not save the raw_time" do
        expect { response }.not_to change(RawTime, :count)
      end

      it "includes the row in problem_rows" do
        expect(response.resources[:problem_rows]).to include(raw_time_row)
      end
    end

    context "when event_group permits notifications" do
      before do
        allow(event_group).to receive(:permit_notifications?).and_return(true)
        allow(BulkProgressNotifier).to receive(:notify)
      end

      it "sends notifications" do
        response
        expect(BulkProgressNotifier).to have_received(:notify)
      end
    end

    context "when event_group does not permit notifications" do
      before { allow(BulkProgressNotifier).to receive(:notify) }

      it "does not send notifications" do
        response
        expect(BulkProgressNotifier).not_to have_received(:notify)
      end
    end
  end
end
