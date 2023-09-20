# frozen_string_literal: true

class MigrateEventLotteriesToConnections < ActiveRecord::Migration[7.0]
  def up
    Event.where.not(lottery_id: nil).find_each do |event|
      event.connections.create!(service_identifier: "internal_lottery", source_id: event.lottery_id, source_type: "Lottery")
    end
  end

  def down
  end
end
