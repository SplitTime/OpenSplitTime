# frozen_string_literal: true

class DeleteTopicResourceKeyJob < ApplicationJob

  queue_as :default

  def perform(record)
    record.delete_topic_resource
  end
end
