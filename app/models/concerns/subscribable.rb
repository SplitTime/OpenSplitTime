# frozen_string_literal: true

# Used for models for which a topic may be generated on a pub-sub service
# such as AWS SNS.

module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :subscribable, dependent: :destroy
    has_many :followers, through: :subscriptions, source: :user
  end

  before_validation :set_topic_resource
  before_destroy :delete_topic_resource

  def set_topic_resource
    if generate_new_topic_resource?
      self.topic_resource_key = SnsTopicManager.generate(resource: self)
    end
  end

  def delete_topic_resource
    if topic_resource_key.present?
      SnsTopicManager.delete(resource: self)
      self.topic_resource_key = nil
    end
  end

  private

  def generate_new_topic_resource?
    topic_resource_key.nil? && slug.present?
  end
end
