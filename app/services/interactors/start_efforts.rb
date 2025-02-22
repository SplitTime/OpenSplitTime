module Interactors
  class StartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args,
                             required: [:efforts],
                             exclusive: [:efforts, :start_time],
                             class: self.class)
      @efforts = args[:efforts]
      @start_time = args[:start_time]
      @errors = []
      @saved_split_times = []
      validate_setup
    end

    def perform!
      unless errors.present?
        SplitTime.transaction do
          efforts.each(&method(:start_effort))
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :efforts, :start_time, :errors, :saved_split_times

    def start_effort(effort)
      split_time = SplitTime.find_or_initialize_by(
        effort_id: effort.id,
        lap: 1,
        split_id: effort.start_split_id,
        bitkey: SubSplit::IN_BITKEY,
      )

      split_time.absolute_time = effort_start_time(effort)

      if split_time.save
        saved_split_times << split_time
      else
        errors << resource_error_object(split_time)
      end
    end

    def effort_start_time(effort)
      converted_start_time || effort.scheduled_start_time || effort.event_start_time
    end

    def converted_start_time
      if start_time.presence.nil?
        nil
      elsif start_time.acts_like?(:time)
        start_time
      elsif start_time.is_a?(String)
        start_time.in_time_zone(time_zone)
      end
    end

    def time_zone
      @time_zone ||= efforts.first&.home_time_zone
    end

    def response_message
      started_time = converted_start_time ? I18n.l(converted_start_time, format: :datetime_input) : "the scheduled start #{pluralize(saved_split_times.size, 'time')}"
      errors.present? ? "No efforts were started" : "Started #{pluralize(saved_split_times.size, 'effort')} at #{started_time}"
    end

    def validate_setup
      if efforts.empty?
        errors << efforts_not_provided_error
        return
      end

      errors << multiple_event_groups_error(event_group_ids) if event_group_ids.uniq.many?
      errors << invalid_start_time_error(start_time) if invalid_start_time?
      errors << invalid_start_time_error(start_time || "nil") unless converted_start_time ||
        efforts.all?(&:scheduled_start_time?) ||
        efforts.all?(&:event)
    end

    def event_group_ids
      @event_group_ids ||= efforts.map { |effort| effort.event.event_group_id }
    end

    def invalid_start_time?
      start_time.is_a?(String) && start_time.present? && start_time.in_time_zone(time_zone).nil?
    end
  end
end
