# frozen_string_literal: true

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
      Rails.logger.info "Generated SNS topic for #{resource.slug}"
      response.topic_arn.include?('arn:aws:sns') ? response.topic_arn : "#{response.topic_arn}:#{SecureRandom.uuid}"
    else
      warn "Unable to generate SNS topic for #{resource.slug}"
      nil
    end
  end

  def delete
    if topic_arn && topic_arn.include?('arn:aws:sns')
      response = sns_client.delete_topic(topic_arn: topic_arn)
      if response.successful?
        Rails.logger.info "Deleted SNS topic #{topic_arn}"
        topic_arn
      else
        warn "Unable to delete SNS topic #{topic_arn}"
        nil
      end
    else
      warn "#{resource.slug} has no topic_resource_key or topic_arn does not exist" unless Rails.env.test?
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
