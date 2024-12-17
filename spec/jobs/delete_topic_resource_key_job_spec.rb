# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteTopicResourceKeyJob do
  subject { described_class.new }

  let(:topic_resource_key) { "arn:aws:sns:test" }

  describe "#perform" do
    let(:perform_job) { subject.perform(topic_resource_key) }
    let(:expected_mock_resource) { OpenStruct.new(topic_resource_key: topic_resource_key, slug: topic_resource_key) }

    before { allow(SnsTopicManager).to receive(:delete) }

    it "sends a message to the topic manager" do
      expect(SnsTopicManager).to receive(:delete).with(resource: expected_mock_resource)
      perform_job
    end
  end
end
