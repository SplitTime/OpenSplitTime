require "rails_helper"

RSpec.describe Webhooks::RaceResultWebhooksController, type: :controller do
  describe "POST #create" do
    let!(:event_group) { create(:event_group) }

    context "with valid new raw data (timing) webhook" do
      let(:timing_payload) do
        {
          event_group_id: event_group.id,
          event_id: "12345",
          webhook_id: "wr_xyz789",
          timestamp: "2025-11-09T14:25:30Z",
          trigger: "new_raw_data",
          raw_data: {
            bib_number: "101",
            split_name: "Mile 10",
            absolute_time: "2025-11-09T14:25:15Z",
            chip_time: "01:23:45",
            status: "OK"
          }
        }
      end

      it "creates a RawTime record" do
        expect {
          post :create, body: timing_payload.to_json, as: :json
        }.to change(RawTime, :count).by(1)

        raw_time = RawTime.last
        expect(raw_time.event_group).to eq(event_group)
        expect(raw_time.bib_number).to eq("101")
        expect(raw_time.split_name).to eq("Mile 10")
        expect(raw_time.source).to eq("raceresult_webhook")
        expect(raw_time.entered_time).to be_present
      end

      it "returns success response with raw_time_id" do
        post :create, body: timing_payload.to_json, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
        expect(json_response["message"]).to eq("Webhook received successfully")
        expect(json_response["raw_time_id"]).to eq(RawTime.last.id)
        expect(json_response["received_at"]).to be_present
      end
    end

    context "with invalid JSON" do
      it "handles parsing errors gracefully" do
        post :create, body: "invalid json", as: :json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Invalid JSON")
      end
    end

    context "with missing required fields" do
      let(:incomplete_payload) do # no event_group_id, no split_name, etc.
        {
          raw_data: {
            bib_number: "101"
          }
        }
      end

      it "does not create a RawTime and returns 422" do
        expect {
          post :create, body: incomplete_payload.to_json, as: :json
        }.not_to change(RawTime, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Failed to create raw time")
      end
    end
  end

  describe "GET #status" do
    it "returns operational status" do
      get :status

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("operational")
      expect(json_response["service"]).to eq("RaceResult Webhook Receiver")
      expect(json_response["version"]).to eq("1.0.0")
    end
  end
end