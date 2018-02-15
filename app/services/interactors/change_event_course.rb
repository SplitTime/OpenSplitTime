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
      @errors = []
      verify_compatibility
    end

    def perform!
      unless errors.present?
        event.course = new_course
        event.splits = new_course.splits
        split_times.each { |st| st.split = splits_by_distance[st.distance_from_start] }
        live_times.each { |lt| lt.split = splits_by_distance[lt.distance_from_start] }
        save_changes
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :event, :new_course, :split_times, :live_times, :errors

    def save_changes
      ActiveRecord::Base.transaction do
        event.save(validate: false) if event.changed?
        split_times.each { |st| save_resource(st) }
        live_times.each { |lt| save_resource(lt) }
        errors << resource_error_object(event) unless event.valid?
        raise ActiveRecord::Rollback if errors.present?
      end
    end

    def save_resource(resource)
      if resource.changed?
        errors << resource_error_object(resource) unless resource.save
      end
    end

    def distances
      @distances ||= splits_by_distance.keys.to_set
    end

    def splits_by_distance
      @splits_by_distance ||= new_course.splits.index_by(&:distance_from_start)
    end

    def response_message
      errors.present? ? "#{event.name} could not be changed to #{new_course.name}. " : "#{event.name} was changed to #{new_course.name}. "
    end

    def verify_compatibility
      errors << distance_mismatch_error(event, new_course) and return unless split_times.all? { |st| distances.include?(st.distance_from_start) }
      errors << distance_mismatch_error(event, new_course) and return unless live_times.all? { |lt| distances.include?(lt.distance_from_start) }
      errors << sub_split_mismatch_error(event, new_course) and return unless split_times.all? { |st| splits_by_distance[st.distance_from_start].sub_split_bitkeys.include?(st.bitkey) }
      errors << sub_split_mismatch_error(event, new_course) unless live_times.all? { |lt| splits_by_distance[lt.distance_from_start].sub_split_bitkeys.include?(lt.bitkey) }
    end
  end
end
