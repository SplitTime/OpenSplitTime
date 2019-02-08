# frozen_string_literal: true

# Used for models for which a topic may be generated on a pub-sub service
# such as AWS SNS. A Subscribable model must implement #generate_new_topic_resource?
# and must have a topic_resource_key attribute.

module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :subscribable, dependent: :destroy
    has_many :followers, through: :subscriptions, source: :user

    before_save :set_topic_resource
    before_destroy :delete_topic_resource
  end

  def set_topic_resource(force: false)
    if (force || generate_new_topic_resource?) && resource_key_buildable?
      self.topic_resource_key = topic_manager.generate(resource: self)
    end
  end

  def delete_topic_resource
    if topic_resource_key.present?
      topic_manager.delete(resource: self)
      self.topic_resource_key = nil
    end
  end

  def topic_manager
    SnsTopicManager
  end

  private

  def resource_key_buildable?
    topic_resource_key.nil? && slug.present?
  end
end
