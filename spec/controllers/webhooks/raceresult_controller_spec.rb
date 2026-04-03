require "rails_helper"

RSpec.describe Webhooks::RaceresultController do
  describe "#receive" do
    subject(:make_request) { post :receive, body: raw_payload }

    let(:raw_payload) { "#{json_data};#{event_group_name}" }

    let(:json_data) do
      {
        "Bib" => bib,
        "TimingPoint" => timing_point,
        "ID" => id,
        "Passing" => {
          "UTCTime" => utc_time,
          "DeviceID" => device_id
        }
      }.to_json
    end

    let(:event_group_name) { "hardrock-2016" }
    let(:bib) { 69 }
    let(:timing_point) { "Start" }
    let(:id) { 162 }
    let(:utc_time) { "2026-03-01T13:46:42.611-06:00" }
    let(:device_id) { "D-55570" }

    context "when the request is valid" do
      before { allow(Interactors::Webhooks::ProcessRaceresultWebhook).to receive(:call).and_return(Interactors::Response.new([], "", [])) }

      it "returns a successful 201 response" do
        make_request

        expect(response.status).to eq(201)
      end

      it "passes raw payload to the interactor" do
        make_request

        expect(Interactors::Webhooks::ProcessRaceresultWebhook).to have_received(:call).with(raw_payload)
      end
    end

    context "when the webhook data matches an existing effort" do
      include ActiveJob::TestHelper

      context "when the event is single-lap" do
        let(:event_group) { event_groups(:hardrock_2014) }
        let(:event_group_name) { event_group.slug }
        let(:effort) { efforts(:hardrock_2014_progress_sherman) }
        let(:split) { splits(:hardrock_cw_cunningham) }
        let(:bib) { effort.bib_number }
        let(:timing_point) { split.base_name }
        let(:utc_time) { "2014-07-13T05:00:00Z" }

        it "enqueues a job to process the raw time" do
          expect { make_request }.to have_enqueued_job(ProcessImportedRawTimesJob)
        end

        it "creates a split_time for the matching effort and split" do
          perform_enqueued_jobs { make_request }

          new_split_time = SplitTime.last
          expect(new_split_time.effort).to eq(effort)
          expect(new_split_time.split).to eq(split)
          expect(new_split_time.lap).to eq(1)
          expect(new_split_time.sub_split_bitkey).to eq(SubSplit::IN_BITKEY)
          expect(new_split_time.absolute_time).to eq(Time.zone.parse("2014-07-13T05:00:00Z"))
          expect(new_split_time.data_status).to eq("good")
        end
      end

      context "when the event is multi-lap" do
        let(:event_group) { event_groups(:rufa_2017) }
        let(:event_group_name) { event_group.slug }
        let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
        let(:split) { splits(:rufa_course_grandeur_peak) }
        let(:bib) { effort.bib_number }
        let(:timing_point) { split.base_name }
        let(:utc_time) { "2017-02-12T02:40:00Z" }

        it "creates a split_time on the correct lap" do
          perform_enqueued_jobs { make_request }

          new_split_time = SplitTime.last
          expect(new_split_time.effort).to eq(effort)
          expect(new_split_time.split).to eq(split)
          expect(new_split_time.lap).to eq(7)
          expect(new_split_time.sub_split_bitkey).to eq(SubSplit::IN_BITKEY)
          expect(new_split_time.absolute_time).to eq(Time.zone.parse("2017-02-12T02:40:00Z"))
          expect(new_split_time.data_status).to eq("good")
        end
      end
    end

    context "when the event group is not found" do
      let(:event_group_name) { "nonexistent-event" }

      it "returns a 422 response" do
        make_request

        expect(response.status).to eq(422)
      end

      it "does not create a RawTime" do
        expect { make_request }.not_to change(RawTime, :count)
      end
    end

    context "when the request data is malformed" do
      let(:raw_payload) { "not_valid_json;hardrock-2016" }

      it "returns a 422 response" do
        make_request

        expect(response.status).to eq(422)
      end

      it "does not create a RawTime" do
        expect { make_request }.not_to change(RawTime, :count)
      end
    end

    context "when the request data is empty" do
      let(:raw_payload) { "" }

      it "returns a 400 response" do
        make_request

        expect(response.status).to eq(400)
      end

      it "does not create a RawTime" do
        expect { make_request }.not_to change(RawTime, :count)
      end
    end
  end
end
