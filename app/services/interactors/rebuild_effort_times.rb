# frozen_string_literal: true

# This Interactor will delete all split_times from an effort and attempt to rebuild split_times
# using only the raw_time records.

# Note: This tool is destructive and will not be beneficial unless a fairly complete
# record of raw_times exists!

module Interactors
  class RebuildEffortTimes
    include Interactors::Errors
    THRESHOLD_TIME = 5.minutes

    def self.perform!(effort:)
      new(effort: effort).perform!
    end

    def initialize(effort:)
      @effort = effort
      @existing_start_time = effort.calculated_start_time
      @errors = []
      @response = Interactors::Response.new([], "", {})
      validate_setup
    end

    def perform!
      unless errors.present?
        ActiveRecord::Base.transaction do
          destroy_split_times
          build_split_times unless errors.present?
          set_effort_status unless errors.present?
          errors << resource_error_object(effort) unless errors.present? || effort.save
          raise ActiveRecord::Rollback if errors.present?
        end
      end

      response.message = "Rebuild completed." if errors.blank?
      response.resources = { effort: effort }
      response
    end

    private

    attr_reader :effort, :existing_start_time, :response
    delegate :event_group, :event, to: :effort
    delegate :errors, to: :response, private: true

    def destroy_split_times
      effort.split_times.each do |st|
        errors << resource_error_object(st) unless st.destroy
      end
      effort.reload
    end

    def build_split_times
      time_points = event.cycled_time_points
      effort.split_times.new(time_point: time_points.next, absolute_time: existing_start_time)

      duplicate_raw_time_chunks.each do |chunk|
        rt = chunk.max_by(&:created_at)
        time_point = time_points.next

        time_point = time_points.next until time_point.sub_split == rt.sub_split

        effort.split_times.new(
          time_point: time_point,
          absolute_time: rt.absolute_time,
          pacer: rt.with_pacer,
          stopped_here: rt.stopped_here,
          remarks: rt.remarks,
          raw_times: chunk,
        )
      end
    end

    def set_effort_status
      Interactors::SetEffortStatus.perform(effort)
    end

    def duplicate_raw_time_chunks
      relevant_raw_times.chunk_while { |i, j| time_is_duplicate?(i, j) }
    end

    def time_is_duplicate?(i, j)
      (i.sub_split == j.sub_split) && ((i.absolute_time - j.absolute_time).abs < THRESHOLD_TIME)
    end

    def relevant_raw_times
      ordered_raw_times.reject { |rt| rt.disassociated_from_effort || rt.absolute_time < existing_start_time }
    end

    def ordered_raw_times
      @raw_times = RawTime.where(event_group_id: event_group.id, matchable_bib_number: effort.bib_number)
                     .with_relation_ids
                     .select(&:absolute_time)
                     .sort_by(&:absolute_time)
    end

    def validate_setup
      errors << single_lap_event_error(self.class) unless event.multiple_laps?
      ordered_raw_times.each do |rt|
        unless valid_sub_splits.any? { |sub_split| sub_split == rt.sub_split }
          errors << invalid_raw_time_error(rt, valid_sub_splits)
        end
        errors << missing_absolute_time_error(rt) unless rt.absolute_time
      end
    end

    def valid_sub_splits
      event.time_points_through(1).map(&:sub_split).to_set
    end
  end
end
