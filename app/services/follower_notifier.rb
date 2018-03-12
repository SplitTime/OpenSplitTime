# frozen_string_literal: true

class FollowerNotifier
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
    response = sns_client.publish(topic_arn: topic_arn, subject: subject, message: message)
    if response.successful?
      response
    else
      logger.info "Unable to publish to #{topic_arn}"
    end
  end

  private

  attr_reader :topic_arn, :effort_data, :sns_client

  def subject
    "Update for #{effort_data[:full_name]} at #{effort_data[:event_name]} from OpenSplitTime"
  end

  def message
    <<~MESSAGE
      The following new #{time_with_verb} reported for #{effort_data[:full_name]} at #{effort_data[:event_name]}:

      #{times_text}

      Full results for #{effort_data[:full_name]} here: #{ENV['BASE_URI']}/efforts/#{effort_data[:effort_slug]}
      Full results for #{effort_data[:event_name]} here: #{ENV['BASE_URI']}/events/#{effort_data[:event_slug]}/spread

      Thank you for using OpenSplitTime!
    MESSAGE
  end

  def times_text
    effort_data[:split_times_data].map do |split_time_data|
      follower_update_body_text(split_time_data)
    end.join("\n")
  end

  def time_with_verb
    effort_data[:split_times_data].one? ? 'time was' : 'times were'
  end
end
