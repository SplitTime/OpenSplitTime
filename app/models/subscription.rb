# frozen_string_literal: true

require 'aws-sdk-sns'

class Subscription < ApplicationRecord
  enum protocol: [:email, :sms, :http, :https]
  belongs_to :user
  belongs_to :subscribable, polymorphic: true

  before_validation :set_resource_key
  before_destroy :delete_resource_key
  after_save :attempt_person_subscription, if: :effort_has_person?
  after_save :attempt_effort_subscriptions, if: :type_is_person?

  validates_presence_of :user_id, :subscribable_type, :subscribable_id, :user, :subscribable, :protocol, :resource_key
  validates :protocol, inclusion: {in: Subscription.protocols.keys}

  def set_resource_key
    if should_generate_resource?
      self.resource_key = SnsSubscriptionManager.generate(subscription: self)
    elsif should_locate_resource?
      key = SnsSubscriptionManager.locate(subscription: self)
      self.resource_key = key if key
    elsif should_update_resource?
      self.resource_key = SnsSubscriptionManager.update(subscription: self)
    end
  end

  def delete_resource_key
    self.resource_key = SnsSubscriptionManager.locate(subscription: self) if should_locate_resource?
    if confirmed?
      SnsSubscriptionManager.delete(subscription: self)
      self.resource_key = nil
    end
  end

  def pending?
    resource_key && resource_key.include?('pending')
  end

  def confirmed?
    resource_key && resource_key.include?('arn:aws:sns')
  end

  def to_s
    "Subscription for #{user.slug} following #{subscribable.slug} by #{protocol}"
  end

  private

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
    subscribable&.topic_resource_key.present? && user&.send(protocol).present?
  end

  def attempt_person_subscription
    person = subscribable.person
    Subscription.find_or_create_by(subscribable: person, user: user, protocol: protocol)
  rescue Aws::SNS::Errors::ServiceError => exception
    logger.warn "  Subscription for #{person.name} could not be created: #{exception.message}"
    true
  end

  def effort_has_person?
    subscribable_type == 'Effort' && subscribable.person&.topic_resource_key.present?
  end

  def attempt_effort_subscriptions
    subscribable.efforts.select(&:topic_resource_key).each do |effort|
      Subscription.find_or_create_by(subscribable: effort, user: user, protocol: protocol)
    rescue Aws::SNS::Errors::ServiceError => exception
      logger.warn "  Subscription for #{effort.name} could not be created: #{exception.message}"
      true
    end
  end

  def type_is_person?
    subscribable_type == 'Person'
  end
end
