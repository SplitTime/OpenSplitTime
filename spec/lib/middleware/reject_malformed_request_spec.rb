# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middleware::RejectMalformedRequest do
  let(:middleware) { described_class.new(app) }
  let(:env) { { "PATH_INFO" => "/", "REMOTE_ADDR" => "192.168.1.1" } }

  def bad_request_with_cause(cause)
    wrapped = ActionController::BadRequest.new("Invalid request parameters")
    wrapped.set_backtrace(caller)
    # Emulate Ruby's cause chain without re-raising (raise-and-rescue inside
    # RSpec #call stubbing loses the cause wiring in some harnesses).
    wrapped.define_singleton_method(:cause) { cause }
    wrapped
  end

  describe "#call" do
    context "with a normal request" do
      let(:app) { ->(_env) { [200, {}, ["OK"]] } }

      it "passes through to the downstream app" do
        status, _headers, body = middleware.call(env)
        expect(status).to eq(200)
        expect(body).to eq(["OK"])
      end
    end

    context "when the downstream app raises ActionController::BadRequest caused by Rack::Multipart::EmptyContentError" do
      let(:app) { ->(_env) { raise bad_request_with_cause(Rack::Multipart::EmptyContentError.new("body empty")) } }

      it "returns 400 Bad Request" do
        status, headers, body = middleware.call(env)
        expect(status).to eq(400)
        expect(headers["Content-Type"]).to eq("text/plain")
        expect(body).to eq(["Bad Request: malformed request parameters"])
      end
    end

    context "when the downstream app raises ActionController::BadRequest caused by Rack::QueryParser::InvalidParameterError" do
      let(:app) { ->(_env) { raise bad_request_with_cause(Rack::QueryParser::InvalidParameterError.new("bad param")) } }

      it "returns 400 Bad Request" do
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(400)
      end
    end

    context "when the downstream app raises ActionController::BadRequest caused by an unrelated error" do
      let(:app) { ->(_env) { raise bad_request_with_cause(RuntimeError.new("something else")) } }

      it "re-raises so legitimate errors still surface" do
        expect { middleware.call(env) }.to raise_error(ActionController::BadRequest)
      end
    end

    context "when the downstream app raises an unrelated exception" do
      let(:app) { ->(_env) { raise ArgumentError, "nope" } }

      it "lets the exception propagate" do
        expect { middleware.call(env) }.to raise_error(ArgumentError)
      end
    end
  end
end
