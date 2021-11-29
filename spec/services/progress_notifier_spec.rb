# frozen_string_literal: true

RSpec.describe ProgressNotifier do
  subject { ProgressNotifier.new(topic_arn: topic_arn, effort_data: effort_data, sns_client: sns_client) }
  let(:topic_arn) { 'arn:aws:sns:us-west-2:998989370925:d-follow_joe-lastname-1' }
  let(:effort_data) { {full_name: 'Joe LastName 1',
                       event_name: 'Test Event 1',
                       split_times_data: [{split_name: 'Split 1 In', split_distance: 10000, absolute_time_local: 'Fri 11:40AM', elapsed_time: '01:40:00', pacer: nil, stopped_here: false},
                                          {split_name: 'Split 1 Out', split_distance: 10000, absolute_time_local: 'Fri 11:50AM', elapsed_time: '01:50:00', pacer: nil, stopped_here: true}],
                       effort_id: 101,
                       effort_slug: 'joe-lastname-1-at-test-event-1'} }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe '#initialize' do
    it 'initializes' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#publish' do
    let(:expected_subject) { 'Update for Joe LastName 1 at Test Event 1 from OpenSplitTime' }
    let(:expected_message) {
      <<~MESSAGE
        Joe LastName 1 made progress at Test Event 1:
        Split 1 In (Mile 6.2), Fri 11:40AM (+01:40:00)
        Split 1 Out (Mile 6.2), Fri 11:50AM (+01:50:00) and stopped there
        Results on OpenSplitTime: #{expected_shortened_url}
      MESSAGE
    }
    let(:expected_shortened_url) { "#{OST::SHORTENED_URI}/#{expected_key}" }
    let(:expected_key) { Shortener::ShortenedUrl.find_by(url: effort_path).unique_key }
    let(:effort_path) { subject.send(:effort_path) }
    let(:stubbed_response) { OpenStruct.new(successful?: true) }

    before { Shortener::ShortenedUrl.generate!(effort_path) }

    it 'sends a message to an SNS client containing the expected information' do
      sns_client.stub_data(:publish)
      expect(sns_client).to receive(:publish).with(topic_arn: topic_arn, subject: expected_subject, message: expected_message).and_return(stubbed_response)
      subject.publish
    end
  end
end
