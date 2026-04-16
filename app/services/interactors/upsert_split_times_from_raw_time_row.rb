# The raw_time_row must have an effort attached to it.
# Each raw_time should already have a new_split_time attached to it,
# for example, as a result of the EnrichRawTimeRow service.

# The new_split_times will overwrite any existing split_times from the same effort on the same time_point.

module Interactors
  class UpsertSplitTimesFromRawTimeRow
    include Interactors::Errors

    ASSIGNABLE_ATTRIBUTES = %w[effort_id lap split split_id sub_split_bitkey absolute_time stopped_here pacer
                               remarks].freeze

    def self.perform!(event_group:, raw_time_row:, times_container: nil)
      new(event_group: event_group, raw_time_row: raw_time_row, times_container: times_container).perform!
    end

    def initialize(event_group:, raw_time_row:, times_container: nil)
      @event_group = event_group
      @raw_time_row = raw_time_row
      @times_container = times_container || SegmentTimesContainer.new(calc_model: :stats)
      @upserted_split_times = []
      @errors = []
      validate_setup
    end

    def perform!
      if errors.blank?
        ActiveRecord::Base.transaction do
          # Acquire a row-level lock on the effort and refresh its split_times to
          # serialize concurrent raw-time processing for the same effort. Without this,
          # two workers can both miss an existing time_point in their in-memory caches
          # and race to insert, hitting the unique index on
          # (effort_id, lap, split_id, sub_split_bitkey). Use a fresh locking query
          # rather than effort.lock! because the effort may already have unpersisted
          # attribute changes from the caller.
          Effort.lock.where(id: effort.id).pick(:id)
          effort.split_times.reload
          valid_raw_times.each { |raw_time| create_and_update_resources(raw_time) }
          update_effort(effort, upserted_split_times)
          if errors.present?
            upserted_split_times.clear
            raise ActiveRecord::Rollback
          end
        end
      end

      raw_time_row.errors ||= []
      raw_time_row.errors += errors
      Interactors::Response.new(errors, "", { upserted_split_times: upserted_split_times })
    end

    private

    attr_reader :event_group, :raw_time_row, :times_container, :upserted_split_times, :errors

    delegate :events, to: :event_group
    delegate :raw_times, :effort, to: :raw_time_row

    def valid_raw_times
      @valid_raw_times ||= raw_times.select(&:new_split_time)
    end

    def create_and_update_resources(raw_time)
      new_split_time = raw_time.new_split_time
      upsert_split_time = effort.split_times.find do |st|
        st.time_point == new_split_time.time_point
      end || effort.split_times.new
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
        errors << resource_error_object(effort) unless effort.save
      else
        errors << combined_response.errors
      end
    end

    def validate_setup
      raise ArgumentError, "upsert_split_times_from_raw_time_row must include event_group" unless event_group
      raise ArgumentError, "upsert_split_times_from_raw_time_row must include raw_time_row" unless raw_time_row

      errors << raw_time_mismatch_error unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
      errors << missing_effort_error unless raw_time_row.effort
      # Allow raw_times without new_split_times (e.g., "Out" raw_time for "In"-only splits)
      # but error if NONE of the raw_times have new_split_times
      return unless raw_times.present? && raw_times.none?(&:new_split_time)

      errors << missing_new_split_time_error(raw_times.first)
    end
  end
end
