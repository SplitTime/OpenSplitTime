# frozen_string_literal: true

# This Interactor will delete all start_times from an effort and attempt to rebuild start_times
# using only the rt records.

# Note: This tool is destructive and will not be beneficial unless a fairly complete
# record of raw_times exists!

module Interactors
  class RebuildEffortTimes
    include Interactors::Errors
    THRESHOLD_TIME = 5.minutes

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:effort, :current_user_id], exclusive: [:effort, :current_user_id], class: self.class)
      @effort = args[:effort]
      @current_user_id = args[:current_user_id]
      @errors = []
      validate_setup
    end

    def perform!
      unless errors.present?
        ActiveRecord::Base.transaction do
          destroy_split_times
          build_split_times unless errors.present?
          errors << resource_error_object(effort) unless errors.present? || effort.save
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      Interactors::Response.new(errors, '', effort: effort)
    end

    private

    attr_reader :effort, :current_user_id, :errors
    delegate :event_group, :event, to: :effort

    def destroy_split_times
      effort.split_times.each do |st|
        unless st.destroy
          errors << resource_error_object(st)
        end
      end
      effort.reload
    end

    def build_split_times
      time_points = event.cycled_time_points
      effort.split_times.new(time_point: time_points.next,
                             absolute_time: effort_start_time,
                             created_by: current_user_id)

      non_duplicated_raw_times.each do |rt|
        time_point = time_points.next

        until time_point.sub_split == rt.sub_split
          time_point = time_points.next
        end

        effort.split_times.new(time_point: time_point, absolute_time: rt.absolute_time, pacer: rt.with_pacer,
                               stopped_here: rt.stopped_here, remarks: rt.remarks, raw_times: [rt],
                               created_by: current_user_id)
      end
    end

    def effort_start_time
      effort.scheduled_start_time || effort.event_start_time
    end

    def non_duplicated_raw_times
      relevant_raw_times.chunk_while { |i, j| time_is_duplicate?(i, j) }.map { |chunk| chunk.max_by(&:created_at) }
    end

    def time_is_duplicate?(i, j)
      (i.sub_split == j.sub_split) && ((i.absolute_time - j.absolute_time).abs < THRESHOLD_TIME)
    end

    def relevant_raw_times
      ordered_raw_times.reject { |rt| rt.absolute_time < effort_start_time }
    end

    def ordered_raw_times
      @raw_times = RawTime.where(event_group_id: event_group.id, bib_number: effort.bib_number).with_relation_ids.sort_by(&:absolute_time)
    end

    def validate_setup
      errors << single_lap_event_error(self.class) unless event.multiple_laps?
      ordered_raw_times.each do |rt|
        errors << invalid_raw_time_error(rt, valid_sub_splits) unless valid_sub_splits.any? { |sub_split| sub_split == rt.sub_split }
        errors << missing_absolute_time_error(rt) unless rt.absolute_time
      end
    end

    def valid_sub_splits
      event.time_points_through(1).map(&:sub_split).to_set
    end
  end
end
