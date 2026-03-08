class SetTopicResourceKeyJob < ApplicationJob
  queue_as :solid_default

  def perform(record)
    record.assign_topic_resource
    record.save
  end
end
