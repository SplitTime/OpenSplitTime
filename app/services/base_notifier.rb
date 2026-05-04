require "aws-sdk-sns"

class BaseNotifier
  include Interactors::Errors

  def self.publish(args)
    new(args).publish
  end

  def initialize(args)
    @topic_arn = args[:topic_arn]
    @sns_client = args[:sns_client] || SnsClientFactory.client
    @subscribable = args[:subscribable]
    post_initialize(args)
  end

  def publish
    sns_response = sns_client.publish(**publish_params)
    Interactors::Response.new([], "Published", response: sns_response, subject: subject, notice_text: message)
  rescue Aws::SNS::Errors::NotFound => e
    self_heal_missing_topic(e)
    Interactors::Response.new([], "Topic missing in AWS — topic_resource_key cleared")
  rescue Aws::SNS::Errors::ServiceError => e
    Interactors::Response.new([aws_sns_error(e)], e.message, {})
  end

  private

  attr_reader :topic_arn, :sns_client, :subscribable

  def self_heal_missing_topic(exception)
    ScoutApm::Context.add(
      subscribable_class: subscribable&.class&.name,
      subscribable_id: subscribable&.id,
      topic_arn: topic_arn,
      self_healed: subscribable.present?,
    )
    ScoutApm::Error.capture(exception)
    subscribable&.update_column(:topic_resource_key, nil)
  end

  def publish_params
    {
      topic_arn: topic_arn,
      subject: subject,
      message: message
    }
  end
end
