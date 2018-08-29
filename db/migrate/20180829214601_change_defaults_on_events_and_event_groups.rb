class ChangeDefaultsOnEventsAndEventGroups < ActiveRecord::Migration[5.1]
  def up
    change_column_default :events, :podium_template, :simple
    change_column_default :event_groups, :auto_live_times, true
    change_column_default :event_groups, :concealed, true
    change_column_default :organizations, :concealed, true
  end

  def down
    change_column_default :events, :podium_template, nil
    change_column_default :event_groups, :auto_live_times, false
    change_column_default :event_groups, :concealed, false
    change_column_default :organizations, :concealed, false
  end
end
