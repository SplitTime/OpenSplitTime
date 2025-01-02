require "rails_helper"

RSpec.describe EventUpdateNotifier do
  subject { described_class.new(topic_arn: topic_arn, event: event, sns_client: sns_client) }
  let(:topic_arn) { "arn:aws:sns:us-west-2:998989370925:d-follow-test-event-1" }
  let(:event) { events(:hardrock_2015) }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe "#initialize" do
    it "initializes" do
      expect { subject }.not_to raise_error
    end
  end

  describe "#publish" do
    let(:expected_subject) { "Update for Hardrock 2015 from OpenSplitTime" }
    let(:stubbed_response) { OpenStruct.new(successful?: true) }
    let(:expected_message) do
      {
        default: "#{event.slug} (#{event.id}) was updated at #{event.updated_at}",
        http: {
          data: {
            type: "events",
            id: event.id,
            attributes: {
              updated_at: event.updated_at,
            }
          }
        }.to_json,
        https: {
          data: {
            type: "events",
            id: event.id,
            attributes: {
              updated_at: event.updated_at,
            }
          }
        }.to_json,
      }.to_json
    end
    let(:expected_args) do
      {
        topic_arn: topic_arn,
        subject: expected_subject,
        message: expected_message,
        message_structure: "json",
      }
    end

    it "sends a message to an SNS client containing the expected information" do
      sns_client.stub_data(:publish)
      expect(sns_client).to receive(:publish).with(expected_args).and_return(stubbed_response)
      subject.publish
    end
  end
end
