require "rails_helper"

RSpec.describe Api::V1::RawTimesController do
  include BitkeyDefinitions

  let(:type) { "raw_times" }
  let(:event_group) { event_groups(:sum) }
  let(:params) { { event_group_id: event_group_id, id: raw_time_id } }
  let(:event_group_id) { event_group&.id }
  let(:raw_time_id) { raw_time&.id }
  let(:event_group) { event_groups(:sum) }
  let(:raw_time) { raw_times(:raw_time_0003) }

  describe "#index" do
    subject(:make_request) { get :index, params: params }
    let(:params) { { event_group_id: event_group_id, filter: filter, sort: sort } }
    let(:filter) { {} }
    let(:sort) { nil }

    via_login_and_jwt do
      context "when an existing event group is provided" do
        context "with no filter or sort" do
          it "returns a 200 response" do
            make_request
            expect(response.status).to eq(200)
          end

          it "returns the first page of raw_times in the event group" do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["data"].size).to eq(25)
            expect(parsed_response["data"].map { |item| item["id"].to_i }).to all be_in(event_group.raw_times.ids)
          end

          it "includes a link to the next page and to the last page in the header" do
            make_request
            header = response.header
            expect(header["Link"]).to include("rel=\"next\"")
            expect(header["Link"]).to include("rel=\"last\"")
          end
        end
      end
    end
  end

  describe "#show" do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context "when an existing event group is provided" do
        context "when the raw time exists and is in the event group" do
          it "returns a successful 200 response" do
            make_request
            expect(response.status).to eq(200)
          end

          it "returns data of a single raw_time" do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["data"]["id"].to_i).to eq(raw_time_id)
            expect(response.body).to be_jsonapi_response_for(type)
          end
        end

        context "when the raw_time exists but is not in the event group" do
          let(:raw_time) { raw_times(:raw_time_0001) }

          it "returns an error" do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["errors"]).to include(/not found/)
            expect(response.status).to eq(404)
          end
        end

        context "when the raw_time does not exist" do
          let(:raw_time_id) { 0 }

          it "returns an error" do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response["errors"]).to include(/not found/)
            expect(response.status).to eq(404)
          end
        end
      end

      context "when the event group id does not exist" do
        let(:event_group_id) { 0 }

        it "returns an error" do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response["errors"]).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
