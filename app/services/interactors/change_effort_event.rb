module Interactors
  class ChangeEffortEvent
    include Interactors::Errors

    def self.perform!(effort:, new_event:)
      new(effort: effort, new_event: new_event).perform!
    end

    def initialize(effort:, new_event:)
      raise ArgumentError, "change_effort_event must include effort" unless effort
      raise ArgumentError, "change_effort_event must include new_event" unless new_event

      @effort = effort
      @new_event = new_event
      @old_event ||= effort.event
      @split_times ||= effort.ordered_split_times
      @existing_splits = old_event.splits
      @errors = []
      verify_compatibility
    end

    def perform!
      if errors.blank?
        effort.event = new_event
        split_times.each { |st| st.split = old_new_split_map[st.split_id] }
        save_changes
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :effort, :old_event, :new_event, :split_times, :existing_splits, :errors

    def save_changes
      ActiveRecord::Base.transaction do
        effort.save(validate: false) if effort.changed?
        split_times.each { |st| st.save if st.changed? }
        effort.reload
        unless effort.valid?
          errors << resource_error_object(effort)
          raise ActiveRecord::Rollback
        end
        effort.set_effort_segments
      end
    end

    def maximum_lap
      @maximum_lap ||= new_event.laps_required.zero? ? Float::INFINITY : new_event.laps_required
    end

    def old_new_split_map
      @old_new_split_map ||= existing_splits.to_h do |existing_split|
        [existing_split.id, matching_new_split(existing_split)]
      end
    end

    def matching_new_split(existing_split)
      new_event.splits.find { |split| split.parameterized_base_name == existing_split.parameterized_base_name }
    end

    def response_message
      if errors.present?
        "#{effort.name} could not be changed from #{old_event.name} to #{new_event.name}. "
      else
        "#{effort.name} was changed from #{old_event.name} to #{new_event.name}. "
      end
    end

    def verify_compatibility
      unless split_times.all? { |st| old_new_split_map[st.split_id] }
        errors << split_name_mismatch_error(effort, new_event) and return
      end
      unless split_times.all? { |st| st.bitkey.in?(old_new_split_map[st.split_id].sub_split_bitkeys) }
        errors << sub_split_mismatch_error(effort, new_event) and return
      end

      errors << lap_mismatch_error(effort, new_event) unless split_times.all? { |st| maximum_lap >= st.lap }
    end
  end
end
