# frozen_string_literal: true

class Subscription < ApplicationRecord
  enum protocol: [:email, :sms, :http, :https]
  belongs_to :user
  belongs_to :subscribable, polymorphic: true

  before_validation :set_resource_key
  before_destroy :delete_resource_key
  validates_presence_of :user_id, :subscribable_type, :subscribable_id, :protocol, :resource_key
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
end
