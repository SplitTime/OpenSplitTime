require "aws-sdk-pinpointsmsvoicev2"

class AwsSmsClient
  def self.fetch_all_opted_out_numbers(opt_out_list_name: "Default")
    client = Aws::PinpointSMSVoiceV2::Client.new(region: ::OstConfig.aws_region)
    numbers = []
    next_token = nil

    loop do
      response = client.describe_opted_out_numbers(
        opt_out_list_name: opt_out_list_name,
        next_token: next_token,
      )
      numbers.concat(response.opted_out_numbers.map(&:opted_out_number))
      next_token = response.next_token
      break if next_token.nil?
    end

    numbers
  end
end
