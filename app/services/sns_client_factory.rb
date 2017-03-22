class SnsClientFactory

  def self.client
    if Rails.env.test?
      Aws::SNS::Client.new(stub_responses: true)
    else
      Aws::SNS::Client.new
    end
  end
end