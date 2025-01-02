require "aws-sdk-sns"

class SnsTopicManager
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
      Rails.logger.error "  Unable to generate SNS topic for #{resource.slug}"
      nil
    end
  rescue Aws::SNS::Errors::ServiceError => e
    Rails.logger.error "  Topic could not be generated: #{e.message}"
    nil
  end

  def delete
    if topic_arn && topic_arn.include?("arn:aws:sns")
      begin
        response = sns_client.delete_topic(topic_arn: topic_arn)

        if response.successful?
          Rails.logger.info "  Deleted SNS topic #{topic_arn}"
          topic_arn
        else
          Rails.logger.error "  Unable to delete SNS topic #{topic_arn}"
          nil
        end
      rescue Aws::SNS::Errors::ServiceError => e
        Rails.logger.error "  Topic could not be deleted: #{e.message}"
        nil
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
