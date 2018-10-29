# frozen_string_literal: true

# The raw_time_row must have an effort attached to it.
# Each raw_time should already have a new_split_time attached to it,
# for example, as a result of the EnrichRawTimeRow service.

# The new_split_times will overwrite any existing split_times from the same effort on the same time_point.

module Interactors
  class UpsertSplitTimesFromRawTimeRow
    include Interactors::Errors
    ASSIGNABLE_ATTRIBUTES = %w[effort_id lap split split_id sub_split_bitkey absolute_time stopped_here pacer remarks]

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:event_group, :raw_time_row],
                             exclusive: [:event_group, :raw_time_row, :times_container],
                             class: self.class)
      @event_group = args[:event_group]
      @raw_time_row = args[:raw_time_row]
      @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
      @upserted_split_times = []
      @errors = []
      validate_setup
    end

    def perform!
      unless errors.present?
        ActiveRecord::Base.transaction do
          raw_times.each { |raw_time| create_and_update_resources(raw_time) }
          update_effort(effort, upserted_split_times)
          if errors.present?
            upserted_split_times.clear
            raise ActiveRecord::Rollback
          end
        end
      end

      raw_time_row.errors ||= []
      raw_time_row.errors += errors
      Interactors::Response.new(errors, '', {upserted_split_times: upserted_split_times})
    end

    private

    attr_reader :event_group, :raw_time_row, :times_container, :upserted_split_times, :errors
    delegate :events, to: :event_group
    delegate :raw_times, :effort, to: :raw_time_row

    def create_and_update_resources(raw_time)
      new_split_time = raw_time.new_split_time
      upsert_split_time = effort.split_times.find { |st| st.time_point == new_split_time.time_point } || effort.split_times.new
      upsert_split_time.assign_attributes(new_split_time.attributes.slice(*ASSIGNABLE_ATTRIBUTES))

      if upsert_split_time.save
        if raw_time.update(split_time_id: upsert_split_time.id)
          upserted_split_times << upsert_split_time
        else
          errors << resource_error_object(raw_time)
        end
      else
        errors << resource_error_object(upsert_split_time)
      end
    end

    def update_effort(effort, upserted_split_times)
      stop_response = nil
      if upserted_split_times.any?(&:stopped_here?)
        stop_response = Interactors::SetEffortStop.perform(effort, split_time_id: upserted_split_times.last.id)
      end
      status_response = Interactors::SetEffortStatus.perform(effort, times_container: times_container)
      combined_response = status_response.merge(stop_response)
      if combined_response.successful?
        unless effort.save
          errors << resource_error_object(effort)
        end
      else
        errors << combined_response.errors
      end
    end

    def validate_setup
      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
      errors << missing_effort_error unless raw_time_row.effort
      errors << missing_new_split_time_error(raw_times.reject(&:new_split_time).first) unless raw_times.all?(&:new_split_time)
    end
  end
end
