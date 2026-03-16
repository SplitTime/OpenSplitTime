# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rails 8.1 Query String Compatibility", type: :request do
  describe "API query parameter parsing" do
    let(:user) { users(:third_user) }
    let(:token) { JsonWebToken.encode({ sub: user.id }) }
    let(:headers) { { "Authorization" => "Bearer #{token}" } }

    context "with bracket notation filters" do
      it "correctly parses filter[name] parameters" do
        get "/api/v1/event_groups", params: { filter: { name: "Hardrock" } }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end

      it "correctly parses filter[available_live] boolean parameters" do
        get "/api/v1/event_groups", params: { filter: { available_live: true } }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end

      it "correctly parses multiple filter parameters" do
        get "/api/v1/event_groups", params: { filter: { name: "Hard", available_live: true } }, headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context "with include parameters" do
      it "correctly parses single include" do
        event = events(:hardrock_2015)
        get "/api/v1/events/#{event.id}", params: { include: "efforts" }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_present
      end

      it "correctly parses comma-separated includes" do
        event = events(:hardrock_2015)
        get "/api/v1/events/#{event.id}", params: { include: "efforts,aid_stations" }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_present
      end
    end

    context "with sort parameters" do
      it "correctly parses ascending sort" do
        get "/api/v1/events", params: { sort: "name" }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end

      it "correctly parses descending sort with minus prefix" do
        get "/api/v1/events", params: { sort: "-name" }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end

      it "correctly parses multiple sort fields" do
        get "/api/v1/events", params: { sort: "name,-scheduled_start_time" }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end
    end

    context "with fields parameter" do
      it "correctly parses fields[events] sparse fieldset" do
        get "/api/v1/events", params: { fields: { events: "name,scheduled_start_time" } }, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end
    end

    context "with complex combined parameters" do
      it "correctly handles filter, include, sort, and fields together" do
        params = {
          filter: { concealed: false },
          include: "event_group,course",
          sort: "-scheduled_start_time",
          fields: { events: "name,scheduled_start_time" }
        }

        get "/api/v1/events", params: params, headers: headers

        expect(response).to have_http_status(:ok)
        parsed = JSON.parse(response.body)
        expect(parsed["data"]).to be_an(Array)
      end
    end
  end

  describe "URL generation with query parameters" do
    it "generates valid URLs with bracket notation" do
      url = event_groups_path(filter: { name: "test" }, format: :json)
      expect(url).to include("filter")
    end

    it "generates valid URLs with array parameters" do
      url = events_path(filter: { id: [1, 2, 3] }, format: :json)
      expect(url).to include("filter")
    end
  end
end
