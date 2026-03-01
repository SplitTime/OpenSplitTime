require "rails_helper"

RSpec.describe Webhooks::RaceresultController do
  describe "#receive" do
    subject(:make_request) { post :receive, body: raw_payload }

    let(:raw_payload) do
      '{"ID":162,"PID":3,"TimingPoint":"Start","Result":-10,"Time":49602.611,"Invalid":false,"Passing":{"Transponder":"69","Position":{"Latitude":39.941129,"Longitude":-104.934041,"Altitude":0,"Flag":"S"},"Hits":2,"RSSI":-77,"Battery":0,"Temperature":0,"WUC":0,"LoopID":0,"Channel":0,"InternalData":"2151f7","StatusFlags":0,"DeviceID":"D-55570","DeviceName":"D-55570","OrderID":210084,"Port":2,"IsMarker":false,"FileNo":32,"PassingNo":1,"Customer":99963,"Received":"2026-03-01T20:46:43.77Z","UTCTime":"2026-03-01T13:46:42.611-06:00"},"Bib":69};hardrock-2016'
    end

    context "when the request is valid" do
      before { allow(Interactors::Webhooks::ProcessRaceresultWebhook).to receive(:call) }

      it "returns a successful 201 response" do
        make_request

        expect(response.status).to eq(201)
      end

      it "passes raw payload to the interactor" do
        make_request

        expect(Interactors::Webhooks::ProcessRaceresultWebhook).to have_received(:call).with(raw_payload)
      end
    end
  end
end