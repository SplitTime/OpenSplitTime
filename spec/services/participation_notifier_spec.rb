# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParticipationNotifier do
  subject { ParticipationNotifier.new(topic_arn: topic_arn, effort: effort, sns_client: sns_client) }
  let(:topic_arn) { 'arn:aws:sns:us-west-2:998989370925:d-follow_rufa-2017-12h-progress-lap2' }
  let(:effort) { efforts(:rufa_2017_12h_progress_lap2) }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }

  describe '#initialize' do

    it 'initializes' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#publish' do
    context 'when the SNS client returns an error' do
      before { sns_client.stub_responses(:publish, 'NotFound') }

      it 'rescues and returns a descriptive error' do
        response = subject.publish
        expect(response.errors.size).to eq(1)
        expect(response.errors.first[:title]).to eq('stubbed-response-error-message')
      end
    end

    context 'when the SNS client returns a successful response' do
      before { sns_client.stub_data(:publish) }

      context 'for an effort in progress' do
        let(:effort) { efforts(:rufa_2017_12h_progress_lap2) }

        it 'sends a message to an SNS client containing the expected information' do
          stubbed_response = OpenStruct.new(successful?: true)
          expected_subject = "#{effort.full_name} is in progress at #{effort.event.name}"
          expected_message = <<~MESSAGE
            Your friend #{effort.full_name} is in progress at #{effort.event.name}!
            Follow along here: #{ENV['BASE_URI']}/efforts/#{effort.id}
            Click the link and sign in to receive live updates for #{effort.first_name}.
            Thank you for using OpenSplitTime!
            You are receiving this message because you signed up on OpenSplitTime and asked to follow #{effort.first_name}. 
            To change your preferences, go to #{ENV['BASE_URI']}/people/#{effort.person.id}, then log in and click to unfollow.
          MESSAGE
          expect(sns_client).to receive(:publish)
                                    .with(topic_arn: topic_arn, subject: expected_subject, message: expected_message)
                                    .and_return(stubbed_response)
          subject.publish
        end

        context 'for an unstarted effort' do
          let(:effort) { efforts(:rufa_2017_12h_not_started) }

          it 'sends a message to an SNS client containing the expected information' do
            stubbed_response = OpenStruct.new(successful?: true)
            expected_subject = "#{effort.full_name} will be participating at #{effort.event.name}"
            expected_message = <<~MESSAGE
              Your friend #{effort.full_name} will be participating at #{effort.event.name}!
              Watch for results here: #{ENV['BASE_URI']}/efforts/#{effort.id}
              Click the link and sign in to receive live updates for #{effort.first_name}.
              Thank you for using OpenSplitTime!
              You are receiving this message because you signed up on OpenSplitTime and asked to follow #{effort.first_name}. 
              To change your preferences, go to #{ENV['BASE_URI']}/people/#{effort.person.id}, then log in and click to unfollow.
            MESSAGE
            expect(sns_client).to receive(:publish)
                                      .with(topic_arn: topic_arn, subject: expected_subject, message: expected_message)
                                      .and_return(stubbed_response)
            subject.publish
          end
        end

        context 'for a finished effort' do
          let(:effort) { efforts(:rufa_2017_12h_finished_first) }

          it 'sends a message to an SNS client containing the expected information' do
            stubbed_response = OpenStruct.new(successful?: true)
            expected_subject = "#{effort.full_name} recently participated at #{effort.event.name}"
            expected_message = <<~MESSAGE
              Your friend #{effort.full_name} recently participated at #{effort.event.name}!
              See full results here: #{ENV['BASE_URI']}/efforts/#{effort.id}

              Thank you for using OpenSplitTime!
              You are receiving this message because you signed up on OpenSplitTime and asked to follow #{effort.first_name}. 
              To change your preferences, go to #{ENV['BASE_URI']}/people/#{effort.person.id}, then log in and click to unfollow.
            MESSAGE
            expect(sns_client).to receive(:publish)
                                      .with(topic_arn: topic_arn, subject: expected_subject, message: expected_message)
                                      .and_return(stubbed_response)
            subject.publish
          end
        end
      end
    end
  end
end
