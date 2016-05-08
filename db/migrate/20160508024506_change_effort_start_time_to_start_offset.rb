class ChangeEffortStartTimeToStartOffset < ActiveRecord::Migration
  def self.up
    add_column :efforts, :start_offset, :integer, default: 0
    execute("UPDATE efforts
SET start_offset = EXTRACT(epoch FROM (start_time - events.first_start_time))
FROM events
WHERE events.id = efforts.event_id")
    remove_column :efforts, :start_time
  end
  def self.down
    add_column :efforts, :start_time, :datetime
    execute("UPDATE efforts
SET start_time = ((start_offset * interval '1 second') + events.first_start_time)
FROM events
WHERE events.id = efforts.event_id")
    remove_column :efforts, :start_offset
  end
end
