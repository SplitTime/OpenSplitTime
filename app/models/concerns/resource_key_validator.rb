class ResourceKeyValidator < ActiveModel::Validator
  def validate(subscription)
    @subscription = subscription
    set_resource_key
  end

  private

  attr_reader :subscription
  delegate :resource_key, :subscribable, :endpoint, to: :subscription

  def set_resource_key
    if should_generate_resource?
      generate_and_set_key
    elsif should_locate_resource?
      locate_and_set_key
    elsif should_update_resource?
      update_and_set_key
    end
  end

  def generate_and_set_key
    response = SnsSubscriptionManager.generate(subscription: subscription)

    if response.successful?
      subscription.resource_key = confirmed_arn?(response.subscription_arn) ? response.subscription_arn : "#{response.subscription_arn}:#{SecureRandom.uuid}"
    else
      subscription.errors.add(:resource_key, "could not be generated: #{response.error_message}")
    end
  end

  def locate_and_set_key
    response = SnsSubscriptionManager.locate(subscription: subscription)

    if response.successful?
      subscription.resource_key = response.subscription_arn
    else
      subscription.errors.add(:resource_key, "could not be located: #{response.error_message}")
    end
  end

  def update_and_set_key
    response = SnsSubscriptionManager.update(subscription: subscription)

    if response.successful?
      subscription.resource_key = response.subscription_arn
    else
      subscription.errors.add(:resource_key, "could not be updated: #{response.error_message}")
    end
  end

  def should_generate_resource?
    resource_key.nil? && required_data_present?
  end

  def should_locate_resource?
    pending? && required_data_present?
  end

  def should_update_resource?
    confirmed? && required_data_present?
  end

  def required_data_present?
    subscribable&.topic_resource_key.present? && endpoint.present?
  end

  def pending?
    resource_key.present? && resource_key.include?("pending")
  end

  def confirmed?
    resource_key.present? && resource_key.include?("arn:aws:sns")
  end

  def confirmed_arn?(string)
    string.include?("arn:aws:sns")
  end
end
