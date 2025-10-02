require "aws-sdk-sns"

class SnsTopicManager
  class TopicNotCreatedError < StandardError; end
  class TopicNotDeletedError < StandardError; end

  def self.generate(args)
    new(**args).generate
  end

  def self.delete(args)
    new(**args).delete
  end

  def initialize(resource:, sns_client: SnsClientFactory.client)
    @resource = resource
    @sns_client = sns_client

    raise "Resource must be provided" if resource.blank?
  end

  def generate
    name = [environment_prefix, "follow", resource.slug].compact.join("-")
    response = sns_client.create_topic(name: name)

    if response.successful?
      Rails.logger.info "  Created SNS topic for #{resource.slug}"
      response.topic_arn.include?("arn:aws:sns") ? response.topic_arn : "#{response.topic_arn}:#{SecureRandom.uuid}"
    else
      raise TopicNotCreatedError, "Unable to generate SNS topic for #{resource.slug}"
    end
  end

  def delete
    if topic_arn && topic_arn.include?("arn:aws:sns")
      begin
        response = sns_client.delete_topic(topic_arn: topic_arn)

        if response.successful?
          Rails.logger.info "  Deleted SNS topic #{topic_arn}"
          topic_arn
        else
          raise TopicNotDeletedError, "Unable to delete SNS topic for #{resource.slug}"
        end
      end

    else
      unless Rails.env.test?
        Rails.logger.error "  #{resource.slug} has no topic_resource_key or topic_arn does not exist"
      end
      nil
    end
  end

  private

  attr_reader :resource, :sns_client

  def topic_arn
    resource.topic_resource_key
  end

  def environment_prefix
    @environment_prefix ||= Rails.env.production? ? nil : "#{Rails.env.first}"
  end
end
