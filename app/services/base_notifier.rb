# frozen_string_literal: true

require 'aws-sdk-sns'

class BaseNotifier
  include Interactors::Errors

  def self.publish(args)
    new(args).publish
  end

  def initialize(args)
    @topic_arn = args[:topic_arn]
    @sns_client = args[:sns_client] || SnsClientFactory.client
    post_initialize(args)
  end

  def publish
    sns_response = sns_client.publish(topic_arn: topic_arn, subject: subject, message: message)
    Interactors::Response.new([], 'Published', response: sns_response, subject: subject, notice_text: message)
  rescue Aws::SNS::Errors::ServiceError => exception
    Interactors::Response.new([aws_sns_error(exception)], exception.message, {})
  end

  private

  attr_reader :topic_arn, :sns_client
end
