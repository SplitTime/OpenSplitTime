class AddDataEntryGroupingStrategyToEventGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :event_groups, :data_entry_grouping_strategy, :integer, default: 0
  end
end
