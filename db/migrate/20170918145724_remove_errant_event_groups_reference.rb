class RemoveErrantEventGroupsReference < ActiveRecord::Migration[5.0]
  def change
    remove_reference :event_groups, :event_groups
  end
end
