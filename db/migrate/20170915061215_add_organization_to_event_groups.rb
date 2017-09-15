class AddOrganizationToEventGroups < ActiveRecord::Migration[5.0]
  def self.up
    add_reference :event_groups, :organization, foreign_key: true

    EventGroup.all.each do |event_group|
      event_group.update!(organization_id: event_group.events.first.organization.id)
    end
  end

  def self.down
    remove_reference :event_groups, :organization
  end
end
