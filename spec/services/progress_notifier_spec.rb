require "rails_helper"

RSpec.describe ProgressNotifier do
  subject { described_class.new(topic_arn: topic_arn, effort_data: effort_data, sns_client: sns_client) }

  let(:topic_arn) { "arn:aws:sns:us-west-2:998989370925:d-follow_joe-lastname-1" }
  let(:effort_data) do
    { full_name: "Joe LastName 1",
      event_name: "Test Event 1",
      split_times_data: [{ split_name: "Split 1 In", split_distance: 10_000, absolute_time_local: "Fri 11:40AM", elapsed_time: "01:40:00", pacer: nil, stopped_here: false },
                         { split_name: "Split 1 Out", split_distance: 10_000, absolute_time_local: "Fri 11:50AM", elapsed_time: "01:50:00", pacer: nil, stopped_here: true }],
      effort_id: 101,
      effort_slug: "joe-lastname-1-at-test-event-1" }
  end
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe "#initialize" do
    it "initializes" do
      expect { subject }.not_to raise_error
    end
  end

  describe "#publish" do
    let(:expected_subject) { "Update for Joe LastName 1 at Test Event 1 from OpenSplitTime" }
    let(:expected_message) do
      <<~MESSAGE
        OpenSplitTime: Joe LastName 1 made progress at Test Event 1:
        Split 1 In (Mile 6.2), Fri 11:40AM (+01:40:00)
        Split 1 Out (Mile 6.2), Fri 11:50AM (+01:50:00) and stopped there
        Results: #{expected_shortened_url}
      MESSAGE
    end
    let(:expected_shortened_url) { "#{::OstConfig.shortened_uri}/s/#{expected_key}" }
    let(:expected_key) { Shortener::ShortenedUrl.find_by(url: effort_path).unique_key }
    let(:effort_path) { subject.send(:effort_path) }

    before { Shortener::ShortenedUrl.generate!(effort_path) }

    context "when no SMS origination number is configured" do
      before { allow(::OstConfig).to receive(:aws_sms_origination_number).and_return(nil) }

      it "sends a message to an SNS client without SMS message attributes" do
        expect(sns_client).to receive(:publish)
          .with(topic_arn: topic_arn, subject: expected_subject, message: expected_message)
        subject.publish
      end
    end

    context "when an SMS origination number is configured" do
      let(:origination_number) { "+13035551212" }
      let(:expected_message_attributes) do
        {
          "AWS.MM.SMS.OriginationNumber" => {
            data_type: "String",
            string_value: origination_number,
          },
        }
      end

      before { allow(::OstConfig).to receive(:aws_sms_origination_number).and_return(origination_number) }

      it "sends a message to an SNS client with the origination number message attribute" do
        expect(sns_client).to receive(:publish)
          .with(
            topic_arn: topic_arn,
            subject: expected_subject,
            message: expected_message,
            message_attributes: expected_message_attributes,
          )
        subject.publish
      end
    end
  end
end
