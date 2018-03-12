# frozen_string_literal: true

module Interactors
  class ChangeEffortEvent
    include Interactors::Errors

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:effort, :new_event], exclusive: [:effort, :new_event], class: self.class)
      @effort = args[:effort]
      @new_event = args[:new_event]
      @old_event ||= effort.event
      @split_times ||= effort.ordered_split_times
      @errors = []
      verify_compatibility
    end

    def perform!
      unless errors.present?
        existing_start_time = effort.start_time
        effort.event = new_event
        effort.start_time = existing_start_time
        split_times.each { |st| st.split = splits_by_distance[st.distance_from_start] }
        save_changes
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :effort, :old_event, :new_event, :split_times, :errors

    def save_changes
      ActiveRecord::Base.transaction do
        effort.save(validate: false) if effort.changed?
        split_times.each { |st| st.save if st.changed? }
        effort.reload
        unless effort.valid?
          errors << resource_error_object(effort)
          raise ActiveRecord::Rollback
        end
      end
    end

    def maximum_lap
      @maximum_lap ||= new_event.laps_required == 0 ? Float::INFINITY : new_event.laps_required
    end

    def distances
      @distances ||= splits_by_distance.keys
    end

    def splits_by_distance
      @splits_by_distance ||= new_event.splits.index_by(&:distance_from_start)
    end

    def response_message
      errors.present? ? "#{effort.name} could not be changed from #{old_event.name} to #{new_event.name}. " :
          "#{effort.name} was changed from #{old_event.name} to #{new_event.name}. "
    end

    def verify_compatibility
      errors << distance_mismatch_error(effort, new_event) and return unless split_times.all? { |st| distances.include?(st.distance_from_start) }
      errors << sub_split_mismatch_error(effort, new_event) and return unless split_times.all? { |st| splits_by_distance[st.distance_from_start].sub_split_bitkeys.include?(st.bitkey) }
      errors << lap_mismatch_error(effort, new_event) unless split_times.all? { |st| maximum_lap >= st.lap }
    end
  end
end
