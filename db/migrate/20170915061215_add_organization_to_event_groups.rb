class AddOrganizationToEventGroups < ActiveRecord::Migration[5.0]
  def self.up
    add_reference :event_groups, :organization, foreign_key: true

    EventGroup.all.each do |event_group|
      event = event_group.events.first
      event_group.assign_attributes(organization_id: event.organization.id,
                                    available_live: event.available_live,
                                    auto_live_times: event.auto_live_times,
                                    concealed: event.concealed)
      event_group.save!
    end
  end

  def self.down
    remove_reference :event_groups, :organization
  end
end
