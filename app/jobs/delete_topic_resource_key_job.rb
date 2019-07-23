# frozen_string_literal: true

class DeleteTopicResourceKeyJob < ApplicationJob

  queue_as :default

  def perform(topic_resource_key)
    mock_resource = OpenStruct.new(topic_resource_key: topic_resource_key, slug: topic_resource_key)
    SnsTopicManager.delete(resource: mock_resource)
  end
end
