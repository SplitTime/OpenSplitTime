require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe FollowerNotifier do
  subject { FollowerNotifier.new(topic_arn: topic_arn, effort_data: effort_data, sns_client: sns_client) }
  let(:topic_arn) { 'arn:aws:sns:us-west-2:998989370925:d-follow_joe-lastname-1' }
  let(:effort_data) { {full_name: 'Joe LastName 1',
                       event_name: 'Test Event 1',
                       split_times_data: [{split_name: 'Split 1 In', split_distance: 10000, day_and_time: 'Friday, July 1, 2016  7:40AM', pacer: nil, stopped_here: false},
                                          {split_name: 'Split 1 Out', split_distance: 10000, day_and_time: 'Friday, July 1, 2016  7:50AM', pacer: nil, stopped_here: true}],
                       effort_slug: 'joe-lastname-1',
                       event_slug: 'test-event-1'} }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe '#initialize' do
    it 'initializes' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#publish' do
    it 'sends a message to an SNS client containing the expected information' do
      sns_client.stub_data(:publish)
      stubbed_response = OpenStruct.new(successful?: true)
      subject = FollowerNotifier.new(topic_arn: topic_arn, effort_data: effort_data, sns_client: sns_client)
      expected_subject = 'Update for Joe LastName 1 at Test Event 1 from OpenSplitTime'
      expected_message = <<~MESSAGE
        The following new times were reported for Joe LastName 1 at Test Event 1:

        Split 1 In (Mile 6.2), Friday, July 1, 2016  7:40AM 
        Split 1 Out (Mile 6.2), Friday, July 1, 2016  7:50AM and stopped there

        Full results for Joe LastName 1 here: #{ENV['BASE_URI']}/efforts/joe-lastname-1
        Full results for Test Event 1 here: #{ENV['BASE_URI']}/events/test-event-1/spread

        Thank you for using OpenSplitTime!
      MESSAGE
      expect(sns_client).to receive(:publish).with(topic_arn: topic_arn, subject: expected_subject, message: expected_message).and_return(stubbed_response)
      subject.publish
    end
  end
end
