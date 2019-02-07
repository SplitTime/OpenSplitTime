# frozen_string_literal: true

class ProgressNotifier
  include MailHelper

  def self.publish(args)
    new(args).publish
  end

  def initialize(args)
    @topic_arn = args[:topic_arn]
    @effort_data = args[:effort_data]
    @sns_client = args[:sns_client] || SnsClientFactory.client
  end

  def publish
    sns_response = sns_client.publish(topic_arn: topic_arn, subject: subject, message: message)
    Interactors::Response.new([], 'Published', response: sns_response, topic_resource_key: topic_arn, subject: subject, notice_text: message)
  rescue Aws::SNS::Errors => error
    Interactors::Response.new([error], 'Not published', response: sns_response, notice_text: nil)
  end

  private

  attr_reader :topic_arn, :effort_data, :sns_client

  def subject
    "Update for #{effort_data[:full_name]} at #{effort_data[:event_name]} from OpenSplitTime"
  end

  def message
    <<~MESSAGE
      #{effort_data[:full_name]} at #{effort_data[:event_name]}:
      #{times_text}
      Full results: #{ENV['BASE_URI']}/efforts/#{effort_data[:effort_id]}
      Thank you for using OpenSplitTime!
    MESSAGE
  end

  def times_text
    effort_data[:split_times_data].map do |split_time_data|
      follower_update_body_text(split_time_data)
    end.join("\n")
  end
end
