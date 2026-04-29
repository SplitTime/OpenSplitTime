require "aws-sdk-pinpointsmsvoicev2"

class AwsSmsClient
  # @return [Hash{String => Time}] phone (E.164) → opted-out timestamp from AWS
  def self.opted_out_at_by_phone(opt_out_list_name: "Default")
    client = Aws::PinpointSMSVoiceV2::Client.new(region: ::OstConfig.aws_region)
    index = {}
    next_token = nil

    loop do
      response = client.describe_opted_out_numbers(
        opt_out_list_name: opt_out_list_name,
        next_token: next_token,
      )
      response.opted_out_numbers.each do |record|
        index[record.opted_out_number] = record.opted_out_timestamp
      end
      next_token = response.next_token
      break if next_token.nil?
    end

    index
  end
end
