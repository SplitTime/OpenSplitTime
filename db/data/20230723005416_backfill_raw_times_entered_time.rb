# frozen_string_literal: true

class BackfillRawTimesEnteredTime < ActiveRecord::Migration[7.0]
  def up
    RawTime.where(entered_time: nil).find_each do |raw_time|
      raw_time.update(entered_time: raw_time.absolute_time.in_time_zone(raw_time.event_group.home_time_zone).to_s)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
