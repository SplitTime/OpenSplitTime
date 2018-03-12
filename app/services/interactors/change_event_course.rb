# frozen_string_literal: true

module Interactors
  class ChangeEventCourse
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:event, :new_course], exclusive: [:event, :new_course], class: self.class)
      @event = args[:event]
      @new_course = args[:new_course]
      @old_course = event.course
      @split_times = event.split_times
      @live_times = event.live_times
      @existing_splits = event.splits
      @errors = []
      verify_compatibility
    end

    def perform!
      unless errors.present?
        event.course = new_course
        split_times.each { |st| st.split = old_new_split_map[st.split_id] }
        live_times.each { |lt| lt.split = old_new_split_map[lt.split_id] }
        save_changes
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :event, :new_course, :old_course, :split_times, :live_times, :existing_splits, :errors

    def save_changes
      ActiveRecord::Base.transaction do
        event.splits = old_new_split_map.values
        save_without_validation(event)
        split_times.each { |st| save_without_validation(st) }
        live_times.each { |lt| save_without_validation(lt) }
        validate_resource(event)
        split_times.each { |st| validate_resource(st) }
        live_times.each { |lt| validate_resource(lt) }
        raise ActiveRecord::Rollback if errors.present?
      end
    end

    def save_without_validation(resource)
      resource.save(validate: false) if resource.changed?
    end

    def validate_resource(resource)
      errors << resource_error_object(resource) unless resource.valid?
    end

    def old_new_split_map
      @old_new_split_map ||= existing_splits.map { |existing_split| [existing_split.id, matching_new_split(existing_split)] }.to_h
    end

    def matching_new_split(existing_split)
      new_course.splits.find { |split| split.distance_from_start == existing_split.distance_from_start }
    end

    def response_message
      errors.present? ? "The course for #{event.name} could not be changed from #{old_course.name} to #{new_course.name}. " :
          "The course for #{event.name} was changed from #{old_course.name} to #{new_course.name}. "
    end

    def verify_compatibility
      errors << distance_mismatch_error(event, new_course) and return unless split_times.all? { |st| old_new_split_map[st.split_id] }
      errors << distance_mismatch_error(event, new_course) and return unless live_times.all? { |lt| old_new_split_map[lt.split_id] }
      errors << sub_split_mismatch_error(event, new_course) and return unless split_times.all? { |st| old_new_split_map[st.split_id].sub_split_bitkeys.include?(st.bitkey) }
      errors << sub_split_mismatch_error(event, new_course) unless live_times.all? { |lt| old_new_split_map[lt.split_id].sub_split_bitkeys.include?(lt.bitkey) }
    end
  end
end
