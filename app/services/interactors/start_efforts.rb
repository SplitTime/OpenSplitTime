# frozen_string_literal: true

module Interactors
  class StartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:efforts, :current_user_id],
                             exclusive: [:efforts, :start_time, :current_user_id],
                             class: self.class)
      @efforts = args[:efforts]
      @start_time = args[:start_time]
      @current_user_id = args[:current_user_id]
      @errors = []
      @saved_split_times = []
      validate_setup
    end

    def perform!
      unless errors.present?
        SplitTime.transaction do
          efforts.each { |effort| start_effort(effort) }
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :efforts, :start_time, :current_user_id, :errors, :saved_split_times

    def start_effort(effort)
      return if effort.split_times.any?(&:starting_split_time?)
      split_time = SplitTime.new(effort_id: effort.id,
                                 time_point: TimePoint.new(1, effort.start_split_id, SubSplit::IN_BITKEY),
                                 absolute_time: converted_start_time,
                                 created_by: current_user_id)
      if split_time.save
        saved_split_times << split_time
      else
        errors << resource_error_object(split_time)
      end
    end

    def converted_start_time
      case
      when start_time.presence.nil?
        nil
      when start_time.acts_like?(:time)
        start_time
      when start_time.is_a?(String)
        start_time.in_time_zone(time_zone)
      else
        nil
      end
    end

    def time_zone
      @time_zone ||= efforts.first.event_home_zone
    end

    def response_message
      errors.present? ? "No efforts were started" : "Started #{pluralize(saved_split_times.size, 'effort')}"
    end

    def validate_setup
      errors << multiple_event_groups_error(event_group_ids) if event_group_ids.uniq.many?
      errors << invalid_start_time_error(start_time || 'nil') unless converted_start_time
    end

    def event_group_ids
      @event_group_ids ||= efforts.map { |effort| effort.event.event_group_id }
    end
  end
end
