require "rails_helper"

RSpec.describe Webhooks::RaceresultController do
  describe "#receive" do
    subject(:make_request) do
      post :receive, params: { token: token }, body: raw_data
    end

    let(:raw_data) do
      {
        record: {
          Bib: bib,
          TimingPoint: timing_point,
          ID: id,
          Passing: {
            UTCTime: utc_time,
            DeviceID: device_id
          }
        },
        event_group_name: event_group_name
      }.to_json
    end

    let(:token) { event_group.webhook_token }
    let(:event_group_name) { event_group.slug }
    let(:event_group) { event_groups(:hardrock_2014) }

    let(:bib) { 69 }
    let(:timing_point) { "Start" }
    let(:id) { 162 }
    let(:utc_time) { "2026-03-01T13:46:42.611-06:00" }
    let(:device_id) { "D-55570" }

    before { event_group.regenerate_webhook_token }

    context "when the request is valid" do
      before { allow(Interactors::Webhooks::ProcessRaceresultWebhook).to receive(:call).and_return(Interactors::Response.new([], "", [])) }

      it "returns a successful 201 response" do
        make_request

        expect(response.status).to eq(201)
      end

      it "passes record and event_group to the interactor" do
        make_request

        expect(Interactors::Webhooks::ProcessRaceresultWebhook).to have_received(:call)
          .with(event_group: event_group, record: anything)
      end
    end

    context "when the webhook data matches an existing effort" do
      include ActiveJob::TestHelper

      context "when the event is single-lap" do
        let(:event_group) { event_groups(:hardrock_2014) }
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

    context "when the token is missing" do
      let(:token) { nil }

      it "returns a 401 response" do
        make_request

        expect(response.status).to eq(401)
      end
    end

    context "when the token is invalid" do
      let(:token) { "wrong-token" }

      it "returns a 401 response" do
        make_request

        expect(response.status).to eq(401)
      end
    end

    context "when the event group is not found" do
      let(:event_group_name) { "nonexistent-event" }
      let(:token) { "any-token" }

      it "raises ActiveRecord::RecordNotFound" do
        expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the record is missing" do
      let(:raw_data) { { event_group_name: event_group_name }.to_json }

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
