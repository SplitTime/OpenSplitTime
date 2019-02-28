# frozen_string_literal: true

module Interactors
  class UpdateEventAndGrouping
    include Interactors::Errors

    def self.perform!(event)
      new(event).perform!
    end

    def initialize(event)
      @event = event
      @event_group_updated = event.event_group_id_changed?
      @old_event_group_id = event.event_group_id_was
      @new_event_group_id = event.event_group_id
      @errors = []
      validate_setup
    end

    def perform!
      ActiveRecord::Base.transaction do
        event.event_group = new_event_group
        errors << resource_error_object(event) unless event.save

        if event_group_orphaned?
          begin
            old_event_group.destroy
          rescue ActiveRecord::ActiveRecordError => exception
            errors << active_record_error(exception)
          end
        end

        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :event, :event_group_updated, :old_event_group, :old_event_group_id, :new_event_group_id, :errors

    def event_group_orphaned?
      old_event_group.reload
      event_group_updated && old_event_group.events.empty?
    end

    def old_event_group
      @old_event_group ||= EventGroup.find_by(id: old_event_group_id)
    end

    def new_event_group
      @new_event_group ||= EventGroup.find_by(id: new_event_group_id) ||
          EventGroup.create!(name: unique_name,
                             organization_id: old_event_group.organization_id,
                             concealed: old_event_group.concealed,
                             available_live: old_event_group.available_live)
    end

    def unique_name
      EventGroup.find_by(name: new_event_group_name) ? "#{new_event_group_name} #{Time.now}" : new_event_group_name
    end

    def new_event_group_name
      "#{event.start_time_local.year} #{old_event_group.organization.name}"
    end

    def message
      if errors.present?
        'Event or event group could not be updated. '
      else
        "Event #{event} was updated. "
      end
    end

    def validate_setup
      errors << mismatched_organization_error(old_event_group, new_event_group) if event_group_updated && old_event_group_id &&
          new_event_group_id && (old_event_group.organization != new_event_group.organization)
    end
  end
end
