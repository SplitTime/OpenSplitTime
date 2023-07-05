# frozen_string_literal: true

class BackfillEventsTopicResourceKeyTake2 < ActiveRecord::Migration[7.0]
  def up
    Event.where("created_at > ?", 6.months.ago).find_each do |event|
      event.assign_topic_resource
      event.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
