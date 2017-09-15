class AddEventGroupIdToEvents < ActiveRecord::Migration[5.0]
  def self.up
    add_reference :events, :event_group, foreign_key: true
  end

  def self.down
    remove_reference :events, :event_group
  end
end
