# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middleware::RejectInvalidUtf8 do
  let(:app) { ->(env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  describe "#call" do
    context "with valid UTF-8 path" do
      let(:env) { { "PATH_INFO" => "/events/123", "REMOTE_ADDR" => "192.168.1.1" } }

      it "passes the request through to the app" do
        status, _headers, body = middleware.call(env)
        expect(status).to eq(200)
        expect(body).to eq(["OK"])
      end
    end

    context "with valid UTF-8 Unicode characters" do
      let(:env) { { "PATH_INFO" => "/events/Test%20%C3%A9v%C3%A8nement", "REMOTE_ADDR" => "192.168.1.1" } }

      it "passes the request through to the app" do
        status, _headers, body = middleware.call(env)
        expect(status).to eq(200)
        expect(body).to eq(["OK"])
      end
    end

    context "with invalid UTF-8 byte sequence" do
      let(:env) { { "PATH_INFO" => "/%c0/", "REMOTE_ADDR" => "192.168.1.1" } }

      it "returns 400 Bad Request" do
        status, headers, body = middleware.call(env)
        expect(status).to eq(400)
        expect(headers["Content-Type"]).to eq("text/plain")
        expect(body).to eq(["Bad Request: Invalid UTF-8 in request path"])
      end

      it "does not pass the request through to the app" do
        expect(app).not_to receive(:call)
        middleware.call(env)
      end
    end

    context "with multiple invalid UTF-8 bytes" do
      let(:env) { { "PATH_INFO" => "/%ff%fe%fd", "REMOTE_ADDR" => "192.168.1.1" } }

      it "returns 400 Bad Request" do
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(400)
      end
    end

    context "with REQUEST_PATH instead of PATH_INFO" do
      let(:env) { { "REQUEST_PATH" => "/%c0/", "REMOTE_ADDR" => "192.168.1.1" } }

      it "returns 400 Bad Request" do
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(400)
      end
    end
  end
end
