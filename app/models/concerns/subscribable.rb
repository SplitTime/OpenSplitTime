# frozen_string_literal: true

# Used for models for which a topic may be generated on a pub-sub service
# such as AWS SNS. A Subscribable model must implement #generate_new_topic_resource?
# and must have a topic_resource_key attribute.

module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :subscribable, dependent: :destroy
    has_many :followers, through: :subscriptions, source: :user

    after_commit :set_topic_resource_job, on: :create
    after_commit :delete_topic_resource_job, on: :destroy
  end

  def assign_topic_resource(force: false)
    if (force || generate_new_topic_resource?) && resource_key_buildable?
      self.topic_resource_key = topic_manager.generate(resource: self)
    end
  end

  def unassign_topic_resource
    if topic_resource_key.present?
      topic_manager.delete(resource: self)
      self.topic_resource_key = nil
    end
  end

  def topic_manager
    SnsTopicManager
  end

  private

  def set_topic_resource_job
    SetTopicResourceKeyJob.perform_later(self)
  end

  def delete_topic_resource_job
    DeleteTopicResourceKeyJob.perform_later(topic_resource_key, topic_manager_string: topic_manager.to_s)
  end

  def resource_key_buildable?
    topic_resource_key.nil? && slug.present?
  end
end
