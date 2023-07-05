# frozen_string_literal: true

require "aws-sdk-sns"

class SnsClientFactory
  # Create a stubbed SNS client if we are testing or if credentials are absent;
  # otherwise create a real SNS client
  #
  # @return [Aws::Sns::Client]
  def self.client
    if Rails.env.test? || ::OstConfig.aws_access_key_id.nil?
      Aws::SNS::Client.new(stub_responses: true)
    else
      Aws::SNS::Client.new
    end
  end
end
