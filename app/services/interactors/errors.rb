module Interactors
  module Errors
    def resource_error_object(record)
      {title: "#{record.class} #{record} could not be saved",
       detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
    end

    def active_record_error(exception)
      {title: "An ActiveRecord exception occurred",
       detail: {exception: exception}}
    end

    def aws_sns_error(exception)
      {title: exception.message,
       detail: {context: exception.context.http_request}}
    end

    def bib_not_found_error(bib_number, filename)
      {title: "Bib not found",
       detail: {error_message: "Bib number #{bib_number} for filename #{filename} was not found"}}
    end

    def connectors_base_error(exception)
      {title: "A connection error occurred",
       detail: {exception: exception.message}}
    end

    def database_error(error_message)
      {title: "A database error occurred",
       detail: {error_message: error_message}}
    end

    def cannot_unstart_error(effort)
      {title: "Cannot mark #{effort} as DNS",
       detail: {messages: ["The effort has one or more intermediate or finish times recorded. Times must be deleted from the effort view."]}}
    end

    def distance_mismatch_error(child, new_parent)
      {title: "Distances do not match",
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because distances do not coincide"]}}
    end

    def duplicate_bib_numbers_error(bib_numbers)
      {title: "Duplicate bib numbers",
       detail: {messages: ["The operation resulted in the creation of duplicate bib numbers: #{bib_numbers.join(', ')}"]}}
    end

    def efforts_not_provided_error
      {title: "Efforts not provided",
       detail: {messages: ["No efforts were provided"]}}
    end

    def empty_bib_numbers_error(problems)
      problem_efforts_text = problems.map { |problem| "#{problem.first} could not be set to #{problem.last}" }.join("\n")
      {title: "Empty bib numbers",
       detail: {messages: ["The operation resulted in the following bib numbers being set to empty: #{problem_efforts_text}"]}}
    end

    def event_group_mismatch_error(resource_1, resource_2)
      {title: "Event group mismatch",
       detail: {messages: ["Event group for #{resource_1} does not match the event group for #{resource_2}"]}}
    end

    def event_not_linked_error
      {title: "Event not linked to source",
       detail: {messages: ["The event has not been linked to a source. Link the event to a source and try again."]}}
    end

    def finish_split_missing_error
      {title: "Finish split missing",
       detail: {messages: ["The event associated with the provided effort has no finish split"]}}
    end

    def invalid_filename_error(filename)
      {title: "Invalid file name",
       detail: {error_message: "File name #{filename} could not be translated into a bib number"}}
    end

    def invalid_raw_time_error(raw_time, valid_sub_splits)
      {title: "Invalid raw time",
       detail: {messages: ["#{raw_time} is invalid; the sub_split #{raw_time.sub_split} must be one of #{valid_sub_splits}"]}}
    end

    def invalid_split_name_error(split_name, valid_split_names)
      {title: "Invalid split name",
       detail: {messages: ["#{split_name} is invalid; valid names are: #{valid_split_names.to_sentence}"]}}
    end

    def invalid_start_time_error(start_time)
      {title: "Invalid start time",
       detail: {messages: ["#{start_time} is not a valid start_time"]}}
    end

    def lap_mismatch_error(child, new_parent)
      {title: "Distances do not match",
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because laps exceed maximum required"]}}
    end

    def lottery_draws_exist_error
      {title: "Lottery draws already exist",
       detail: {messages: ["Draws already exist for this lottery; please delete them before running this operation"]}}
    end

    def lottery_entrants_not_created_error
      {title: "No lottery entrants exist",
       detail: {messages: ["No entrants have yet been created for this lottery"]}}
    end

    def lottery_tickets_not_generated_error
      {title: "No lottery tickets exist",
       detail: {messages: ["Tickets have not yet been generated for this lottery"]}}
    end

    def missing_absolute_time_error(raw_time)
      {title: "Missing absolute time",
       detail: {messages: ["Raw time #{raw_time} is missing an absolute time"]}}
    end

    def missing_effort_error
      {title: "Missing effort",
       detail: {messages: ["The raw_time is missing an effort"]}}
    end

    def missing_new_split_time_error(raw_time)
      {title: "Raw time does not contain a new_split_time",
       detail: {messages: ["#{raw_time} does not have a new_split_time"]}}
    end

    def nokogiri_parse_error(exception)
      {title: "An error occurred while attempting to parse the file",
       detail: {exception: exception}}
    end

    def raw_time_mismatch_error
      {title: "Raw times do not match",
       detail: {messages: ["One or more raw times is not related to the provided event group"]}}
    end

    def single_lap_event_error(interactor)
      {title: "Event cannot be a single lap",
       detail: {messages: ["The event must be multi-lap to use #{interactor}"]}}
    end

    def split_name_mismatch_error(child, new_parent)
      {title: "Split names do not match",
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because #{child} has split times corresponding to split names that do not coincide with splits for #{new_parent}"]}}
    end

    def sub_split_mismatch_error(child, new_parent)
      {title: "Distances do not match",
       detail: {messages: ["#{child} cannot be assigned to #{new_parent} because sub splits do not coincide"]}}
    end

    def multiple_event_groups_error(event_group_ids)
      {title: "Efforts are from multiple event groups",
       detail: {messages: ["Attempted to start efforts from multiple event_groups: #{event_group_ids.to_sentence}"]}}
    end

    def multiple_runsignup_race_ids_error(race_ids, event_group_id)
      {title: "Multiple race ids assigned to event group",
       detail: {messages: ["Multiple runsignup race ids (#{race_ids.to_sentence}) are assigned to a single event group (#{event_group_id})"]}}
    end

    def mismatched_organization_error(old_event_group, new_event_group)
      {title: "Event group organizations do not match",
       detail: {messages: ["The event cannot be updated because #{old_event_group} is organized under #{old_event_group.organization}, but #{new_event_group} is organized under #{new_event_group.organization}"]}}
    end

    def no_runsignup_race_id_error(event_group_id)
      {title: "No race id assigned to event group",
       detail: {messages: ["No runsignup race id is assigned to event group #{event_group_id}"]}}
    end

    def effort_offset_failure_error(effort)
      {title: "Effort offset could not be adjusted",
       detail: {messages: ["The starting split time for #{effort} was beyond an existing later split time"]}}
    end
  end
end
