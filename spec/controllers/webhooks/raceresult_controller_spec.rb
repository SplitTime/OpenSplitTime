require 'rails_helper'

RSpec.describe "Webhooks::Raceresults", type: :request do
  describe "POST /webhooks/raceresult" do
    let(:valid_payload) do
      {
        "ID" => 115,
        "TimingPoint" => "5K",
        "Bib" => 69,
        "Passing" => {
          "DeviceID" => "D-55570",
          "UTCTime" => "2026-02-15T22:25:18.989-06:00"
        }
      }.to_json
    end

    it "extracts specific fields and returns 200 OK" do
      post "/webhooks/raceresult", params: valid_payload, headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)["data"]
      expect(json_response["bib"]).to eq(69)
      expect(json_response["timing_point"]).to eq("5K")
      expect(json_response["device_id"]).to eq("D-55570")
    end

    it "returns 400 Bad Request when the body is empty" do
      post "/webhooks/raceresult", params: "", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:bad_request)
    end

    it "handles missing nested fields gracefully (dig test)" do
      payload_without_passing = { "ID" => 1, "Bib" => 10 }.to_json
      post "/webhooks/raceresult", params: payload_without_passing
      
      json_response = JSON.parse(response.body)["data"]
      expect(json_response["utc_time"]).to be_nil
      expect(json_response["device_id"]).to be_nil
    end
  end
end