require "rails_helper"

RSpec.describe ::NamespaceRedirector do
  subject { described_class.new(model) }
  let(:model) { "courses" }

  describe "#call" do
    let(:result) { subject.call(params, _request) }
    let(:params) { { path: path } }
    let(:_request) { nil }

    context "when the path has no tail" do
      let(:path) { "hardrock-ccw" }
      it "returns a namespaced url string" do
        expect(result).to eq("/organizations/hardrock/courses/hardrock-ccw")
      end
    end

    context "when the path has a tail" do
      let(:path) { "hardrock-ccw/best_efforts" }
      it "returns a namespaced url string that includes the tail" do
        expect(result).to eq("/organizations/hardrock/courses/hardrock-ccw/best_efforts")
      end
    end

    context "when path is empty string" do
      let(:path) { "" }
      it "raises an error" do
        expect { result }.to raise_error ArgumentError
      end
    end

    context "when path is nil" do
      let(:path) { nil }
      it "raises an error" do
        expect { result }.to raise_error ArgumentError
      end
    end
  end
end
