# frozen_string_literal: true

class SetTopicResourceKeyJob < ApplicationJob

  queue_as :default

  def perform(record)
    record.set_topic_resource
  end
end
