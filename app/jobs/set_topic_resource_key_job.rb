# frozen_string_literal: true

class SetTopicResourceKeyJob < ApplicationJob

  queue_as :default

  def perform(record)
    record.assign_topic_resource
    record.save
  end
end
