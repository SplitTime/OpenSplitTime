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
      @existing_splits = old_event.splits
      @errors = []
      verify_compatibility
    end

    def perform!
      unless errors.present?
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
      end
    end

    def maximum_lap
      @maximum_lap ||= new_event.laps_required == 0 ? Float::INFINITY : new_event.laps_required
    end

    def old_new_split_map
      @old_new_split_map ||= existing_splits.map { |existing_split| [existing_split.id, matching_new_split(existing_split)] }.to_h
    end

    def matching_new_split(existing_split)
      new_event.splits.find { |split| split.parameterized_base_name == existing_split.parameterized_base_name }
    end

    def response_message
      errors.present? ? "#{effort.name} could not be changed from #{old_event.name} to #{new_event.name}. " :
          "#{effort.name} was changed from #{old_event.name} to #{new_event.name}. "
    end

    def verify_compatibility
      errors << split_name_mismatch_error(effort, new_event) and return unless split_times.all? { |st| old_new_split_map[st.split_id] }
      errors << sub_split_mismatch_error(effort, new_event) and return unless split_times.all? { |st| st.bitkey.in?(old_new_split_map[st.split_id].sub_split_bitkeys) }
      errors << lap_mismatch_error(effort, new_event) unless split_times.all? { |st| maximum_lap >= st.lap }
    end
  end
end
