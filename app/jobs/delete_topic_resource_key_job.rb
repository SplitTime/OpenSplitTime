class DeleteTopicResourceKeyJob < ApplicationJob
  MockResource = Struct.new(:topic_resource_key, :slug, keyword_init: true)

  queue_as :default

  def perform(topic_resource_key, topic_manager_string: "SnsTopicManager")
    topic_manager = topic_manager_string.constantize
    mock_resource = MockResource.new(topic_resource_key: topic_resource_key, slug: topic_resource_key)
    topic_manager.delete(resource: mock_resource)
  end
end
