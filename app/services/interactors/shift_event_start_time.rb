module Interactors
  class ShiftEventStartTime
    include Interactors::Errors
    include TimeFormats

    def self.perform!(event, new_start_time:)
      new(event, new_start_time: new_start_time).perform!
    end

    def initialize(event, new_start_time:)
      @event = event
      @non_localized_new_start_time = new_start_time
      validate_setup

      @new_start_time = new_start_time.in_time_zone(event.home_time_zone)
      @old_start_time = event.scheduled_start_time_local
      @current_user = User.current
      @errors = []
    end

    def perform!
      unless errors.present? || shift_seconds.zero?
        ActiveRecord::Base.transaction do
          update_event
          update_efforts
          update_split_times
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :event, :non_localized_new_start_time, :new_start_time, :old_start_time, :current_user, :errors

    def update_event
      event.update!(scheduled_start_time: new_start_time)
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def update_efforts
      ActiveRecord::Base.connection.execute(effort_query)
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def update_split_times
      ActiveRecord::Base.connection.execute(split_time_query)
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def effort_query
      EffortQuery.shift_event_scheduled_times(event, shift_seconds)
    end

    def split_time_query
      SplitTimeQuery.shift_event_absolute_times(event, shift_seconds)
    end

    def shift_seconds
      new_start_time - old_start_time
    end

    def shift_direction
      new_start_time > old_start_time ? :back : :forward
    end

    def response_message
      if errors.present?
        "The start time for #{event.name} could not be shifted " \
          "from #{flexible_format(old_start_time, new_start_time)} " \
          "to #{flexible_format(new_start_time, old_start_time)}. "
      elsif shift_seconds.zero?
        "The new start time for #{event.name} was #{flexible_format(new_start_time, old_start_time)}, " \
          "unchanged from the old start time. "
      else
        "The start time for #{event.name} was shifted #{shift_direction} " \
          "from #{flexible_format(old_start_time, new_start_time)} " \
          "to #{flexible_format(new_start_time, old_start_time)}. " \
          "All related scheduled start times and split times were shifted #{shift_direction} by the same amount."
      end
    end

    def validate_setup
      raise ArgumentError, "shift_event_start_time must include event" unless event
      raise ArgumentError, "event must be an Event" unless event.is_a?(Event)
      raise ArgumentError, "shift_event_start_time must include new_start_time" unless non_localized_new_start_time
    end
  end
end
