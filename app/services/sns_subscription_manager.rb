# frozen_string_literal: true

require "aws-sdk-sns"

class SnsSubscriptionManager
  Response = Struct.new(:error_message, :subscription_arn, keyword_init: true) do
    def successful?
      error_message.blank?
    end
  end

  # @return [SnsSubscriptionManager::Response]
  def self.generate(args)
    new(**args).generate
  end

  # @return [SnsSubscriptionManager::Response]
  def self.delete(args)
    new(**args).delete
  end

  # @return [SnsSubscriptionManager::Response]
  def self.locate(args)
    new(**args).locate
  end

  # @return [SnsSubscriptionManager::Response]
  def self.update(args)
    new(**args).update
  end

  # @param [Subscription] subscription
  # @param [Aws::Sns::Client] sns_client
  def initialize(subscription:, sns_client: SnsClientFactory.client)
    @subscription = subscription
    @sns_client = sns_client
    @response = Response.new
  end

  # @return [SnsSubscriptionManager::Response]
  def generate
    sns_response = sns_client.subscribe(topic_arn: topic_arn, protocol: protocol, endpoint: endpoint)

    if sns_response.successful?
      response.subscription_arn = sns_response.subscription_arn
    else
      response.error_message = sns_response.error_message
    end
  rescue Aws::SNS::Errors::ServiceError => error
    response.error_message = "#{subscription} could not be generated: #{error.message}"
  ensure
    return response
  end

  # @return [SnsSubscriptionManager::Response]
  def delete
    if subscription.confirmed?
      sns_response = sns_client.unsubscribe(subscription_arn: subscription_arn)
      if sns_response.successful?
        response.subscription_arn = subscription_arn
      else
        response.error_message = sns_response.error_message
      end
    else
      response.error_message = "#{subscription} is unconfirmed or does not exist"
    end
  rescue Aws::SNS::Errors::ServiceError => error
    response.error_message = "#{subscription} could not be deleted: #{error.message}"
  ensure
    return response
  end

  # @return [SnsSubscriptionManager::Response]
  def locate
    next_token = ""
    found_subscription = nil
    while next_token && !found_subscription
      sns_response = sns_client.list_subscriptions_by_topic(topic_arn: topic_arn)
      subs_by_topic = sns_response.subscriptions
      next_token = sns_response.next_token
      found_subscription = subs_by_topic.find { |sub| sub.endpoint == endpoint }
    end

    if found_subscription.present?
      if confirmed_arn?(found_subscription.subscription_arn)
        response.subscription_arn = found_subscription.subscription_arn
      else
        response.error_message = "#{subscription} is unconfirmed"
      end
    else
      response.error_message = "#{subscription} does not exist"
    end
  rescue Aws::SNS::Errors::ServiceError => error
    response.error_message = "#{subscription} could not be located: #{error.message}"
  ensure
    return response
  end

  # @return [SnsSubscriptionManager::Response]
  def update
    sns_response = sns_client.get_subscription_attributes(subscription_arn: subscription_arn)

    attributes = sns_response.attributes.deep_transform_keys(&:underscore).with_indifferent_access
    if (attributes[:endpoint] == endpoint) && (attributes[:protocol] == protocol)
      response.subscription_arn = subscription_arn
      response
    else
      delete_response = delete
      if delete_response.successful?
        generate
      else
        delete_response
      end
    end
  end

  private

  attr_reader :subscription, :sns_client, :response

  delegate :endpoint, :subscribable, :user, :protocol, :resource_key, to: :subscription

  def topic_arn
    @topic_arn ||= subscribable.topic_resource_key
  end

  def subscription_arn
    @subscription_arn ||= resource_key
  end

  def confirmed_arn?(string)
    string.include?("arn:aws:sns")
  end
end
