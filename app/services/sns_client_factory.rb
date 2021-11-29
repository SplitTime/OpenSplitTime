# frozen_string_literal: true

require 'aws-sdk-sns'

class SnsClientFactory

  # Create a stubbed SNS client if we are testing or if credentials are absent;
  # otherwise create a real SNS client
  def self.client
    if Rails.env.test? || ENV['AWS_ACCESS_KEY_ID'].nil?
      Aws::SNS::Client.new(stub_responses: true)
    else
      Aws::SNS::Client.new
    end
  end
end
