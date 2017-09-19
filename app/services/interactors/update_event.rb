module Interactors
  class UpdateEvent

    def self.perform!(event)
      new(event).perform!
    end

    def initialize(event)
      @event = event
      @event_group_updated = event.event_group_id_changed?
      @old_event_group_id = event.event_group_id_was
      @new_event_group_id = event.event_group_id
      @response = Interactors::Response.new([])
    end

    def perform!
      ActiveRecord::Base.transaction do
        event.event_group = new_event_group
        event.save
        response.errors += event.errors.full_messages
        if event_group_orphaned?
          begin
            self.destroyed_event_group = old_event_group.destroy
          rescue ActiveRecord::ActiveRecordError => exception
            response.errors << exception
          end
        end
        if response.errors.present?
          raise ActiveRecord::Rollback
        else
          response.message = event_saved_message
          response.message += event_group_destroyed_message if event_group_destroyed?
        end
      end
      response
    end

    private

    attr_reader :event, :event_group_updated, :old_event_group, :old_event_group_id, :new_event_group_id, :response
    attr_accessor :destroyed_event_group

    def event_group_orphaned?
      old_event_group.reload
      event_group_updated && old_event_group.events.empty?
    end

    def event_group_destroyed?
      destroyed_event_group.is_a?(EventGroup)
    end

    def old_event_group
      @old_event_group ||= EventGroup.find_by(id: old_event_group_id)
    end

    def new_event_group
      @new_event_group ||= EventGroup.find_by(id: new_event_group_id) ||
          EventGroup.create!(name: unique_name,
                             organization_id: old_event_group.organization_id,
                             concealed: old_event_group.concealed,
                             auto_live_times: old_event_group.auto_live_times,
                             available_live: old_event_group.available_live)
    end

    def unique_name
      EventGroup.find_by(name: event.name) ? "#{event.name} #{Time.now}" : event.name
    end

    def event_saved_message
      "Event #{event} was saved. "
    end

    def event_group_destroyed_message
      "Event group #{destroyed_event_group.name}, which was formerly related to the event, was deleted. "
    end
  end
end
