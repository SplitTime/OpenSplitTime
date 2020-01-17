# frozen_string_literal: true

require 'aws-sdk-sns'

class SnsTopicManager
  def self.generate(args)
    new(args).generate
  end

  def self.delete(args)
    new(args).delete
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: :resource, exclusive: [:resource, :sns_client], class: self.class)
    @resource = args[:resource]
    @sns_client = args[:sns_client] || SnsClientFactory.client
  end

  def generate
    response = sns_client.create_topic(name: "#{environment_prefix}follow_#{resource.slug}")

    if response.successful?
      Rails.logger.info "  Created SNS topic for #{resource.slug}"
      response.topic_arn.include?('arn:aws:sns') ? response.topic_arn : "#{response.topic_arn}:#{SecureRandom.uuid}"
    else
      Rails.logger.error "  Unable to generate SNS topic for #{resource.slug}"
      nil
    end

  rescue Aws::SNS::Errors::ServiceError => exception
    Rails.logger.error "  Topic could not be generated: #{exception.message}"
    nil
  end

  def delete
    if topic_arn && topic_arn.include?('arn:aws:sns')
      begin
        response = sns_client.delete_topic(topic_arn: topic_arn)

        if response.successful?
          Rails.logger.info "  Deleted SNS topic #{topic_arn}"
          topic_arn
        else
          Rails.logger.error "  Unable to delete SNS topic #{topic_arn}"
          nil
        end

      rescue Aws::SNS::Errors::ServiceError => exception
        Rails.logger.error "  Topic could not be deleted: #{exception.message}"
        nil
      end

    else
      Rails.logger.error "  #{resource.slug} has no topic_resource_key or topic_arn does not exist" unless Rails.env.test?
      nil
    end
  end

  private

  attr_reader :resource, :sns_client

  def topic_arn
    resource.topic_resource_key
  end

  def environment_prefix
    @environment_prefix ||= Rails.env.production? ? '' : "#{Rails.env.first}-"
  end
end
