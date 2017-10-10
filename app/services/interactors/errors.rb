module Interactors
  module Errors
    def resource_error_object(record)
      {title: "#{record.class} #{record} could not be saved",
       detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
    end

    def active_record_error(exception)
      {title: 'An ActiveRecord exception occurred',
      detail: {exception: exception}}
    end

    def mismatched_organization_error(old_event_group, new_event_group)
      {title: 'Event group organizations do not match',
       detail: {message: "The event cannot be updated because #{old_event_group} is organized under #{old_event_group.organization}, but #{new_event_group} is organized under #{new_event_group.organization}"}}
    end
  end
end
