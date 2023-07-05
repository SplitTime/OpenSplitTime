# frozen_string_literal: true

class BackfillEventsTopicResourceKey < ActiveRecord::Migration[7.0]
  def up
    Event.find_each do |event|
      event.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
