class SetTopicResourceKeyJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(record)
    record.assign_topic_resource
    record.save
  end
end
