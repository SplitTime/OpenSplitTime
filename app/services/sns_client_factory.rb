# frozen_string_literal: true

class SnsClientFactory

  # Create a real SNS client if credentials are present; otherwise create a stubbed SNS client
  def self.client
    if ENV['AWS_ACCESS_KEY_ID']
      Aws::SNS::Client.new
    else
      Aws::SNS::Client.new(stub_responses: true)
    end
  end
end
