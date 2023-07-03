# frozen_string_literal: true

require "rails_helper"

RSpec.describe SnsTopicManager do
  subject { described_class.new(resource: resource, sns_client: sns_client) }
  let(:resource) { events(:hardrock_2015) }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe ".generate" do
    let(:result) { described_class.generate(resource: resource) }

    it "does not raise an error" do
      expect { result }.not_to raise_error
    end
  end

  describe ".delete" do
    let(:result) { described_class.delete(resource: resource) }

    it "does not raise an error" do
      expect { result }.not_to raise_error
    end
  end

  describe "#generate" do
    let(:result) { subject.generate }
    before { allow(sns_client).to receive(:create_topic).and_call_original }

    context "when resource is provided" do
      it "passes a topic name based on the resource slug to the SNS client" do
        expect(sns_client).to receive(:create_topic).with(name: "t-follow-#{resource.slug}")
        result
      end

      it "returns a topic_arn" do
        expect(result).to be_a(String)
        expect(result).to start_with("topicARN:")
      end
    end

    context "when resource is nil" do
      let(:resource) { nil }

      it "raises an error" do
        expect { result }.to raise_error("Resource must be provided")
      end
    end
  end

  describe "#delete" do
    let(:result) { subject.delete }
    before { allow(sns_client).to receive(:delete_topic).and_call_original }

    context "when the resource has a topic_resource_key" do
      before { resource.update(topic_resource_key: topic_arn) }

      context "beginning with 'arn:aws:sns'" do
        let(:topic_arn) { "arn:aws:sns:123" }

        it "attempts to delete the topic" do
          expect(sns_client).to receive(:delete_topic).with(topic_arn: topic_arn)
          result
        end

        it "returns the deleted topic_arn" do
          expect(result).to eq(topic_arn)
        end
      end

      context "that does not begin with 'arn:aws:sns'" do
        let(:topic_arn) { "topicARN:123" }

        it "does not attempt to delete the topic" do
          expect(sns_client).not_to receive(:delete_topic)
          result
        end

        it { expect(result).to be_nil }
      end
    end

    context "when resource is nil" do
      let(:resource) { nil }

      it "raises an error" do
        expect { result }.to raise_error("Resource must be provided")
      end
    end
  end
end
