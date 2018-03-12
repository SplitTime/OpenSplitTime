# frozen_string_literal: true

class SnsSubscriptionManager

  def self.generate(args)
    new(args).generate
  end

  def self.delete(args)
    new(args).delete
  end

  def self.locate(args)
    new(args).locate
  end

  def self.update(args)
    new(args).update
  end

  def initialize(args)
    ArgsValidator.validate(params: args, required: :subscription, exclusive: [:subscription, :sns_client], class: self.class)
    @subscription = args[:subscription]
    @sns_client = args[:sns_client] || SnsClientFactory.client
  end

  def generate
    response = sns_client.subscribe(topic_arn: topic_arn,
                                    protocol: protocol,
                                    endpoint: endpoint)
    if response.successful?
      print '.' unless Rails.env.test?
      Rails.logger.info "Generated #{subscription}"
      confirmed_arn?(response.subscription_arn) ? response.subscription_arn : "#{response.subscription_arn}:#{SecureRandom.uuid}"
    else
      print 'X' unless Rails.env.test?
      warn "Unable to generate #{subscription}"
      nil
    end
  end

  def delete
    if subscription.confirmed?
      response = sns_client.unsubscribe(subscription_arn: subscription_arn)
      if response.successful?
        print '.' unless Rails.env.test?
        Rails.logger.info "Deleted SNS subscription #{subscription_arn}"
        subscription_arn
      else
        print 'X' unless Rails.env.test?
        warn "Unable to delete #{subscription}"
        nil
      end
    else
      print '-' unless Rails.env.test?
      warn "#{subscription} is unconfirmed or does not exist"
    end
  end

  def locate
    next_token = ''
    found_subscription = nil
    while next_token && !found_subscription
      response = sns_client.list_subscriptions_by_topic(topic_arn: topic_arn)
      subs_by_topic = response.subscriptions
      next_token = response.next_token
      found_subscription = subs_by_topic.find { |sub| sub.endpoint == endpoint }
    end
    (found_subscription && confirmed_arn?(found_subscription.subscription_arn)) ?
        found_subscription.subscription_arn : nil
  end

  def update
    response = sns_client.get_subscription_attributes(subscription_arn: subscription_arn)
    attributes = response.attributes.underscore_keys
    if (attributes[:endpoint] == endpoint) && (attributes[:protocol] == protocol)
      subscription_arn
    else
      delete
      generate
    end
  end

  private

  attr_reader :subscription, :sns_client
  delegate :person, :user, :protocol, :resource_key, to: :subscription

  def endpoint
    @endpoint ||= user.send(protocol)
  end

  def topic_arn
    @topic_arn ||= person.topic_resource_key
  end

  def subscription_arn
    @subscription_arn ||= resource_key
  end

  def confirmed_arn?(string)
    string.include?('arn:aws:sns')
  end
end
