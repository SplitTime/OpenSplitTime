# frozen_string_literal: true

module Interactors
  class ShiftEventStartTime
    include Interactors::Errors
    include TimeFormats

    def self.perform!(event, args)
      new(event, args).perform!
    end

    def initialize(event, args)
      ArgsValidator.validate(subject: event,
                             subject_class: Event,
                             params: args,
                             required: [:new_start_time],
                             exclusive: [:new_start_time],
                             class: self.class)
      @event = event
      @new_start_time = args[:new_start_time].in_time_zone(event.home_time_zone)
      @old_start_time = event.start_time_local
      @current_user = User.current
      @errors = []
    end

    def perform!
      unless errors.present? || shift_seconds == 0
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

    def update_event
      event.update!(start_time: new_start_time)
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def update_efforts
      ActiveRecord::Base.connection.execute(effort_query)
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def update_split_times
      ActiveRecord::Base.connection.execute(split_time_query)
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    attr_reader :event, :new_start_time, :old_start_time, :current_user, :errors

    def effort_query
      EffortQuery.shift_event_scheduled_times(event, shift_seconds, current_user)
    end

    def split_time_query
      SplitTimeQuery.shift_event_absolute_times(event, shift_seconds, current_user)
    end

    def shift_seconds
      new_start_time - old_start_time
    end

    def shift_direction
      new_start_time > old_start_time ? :back : :forward
    end

    def response_message
      case
      when errors.present?
        "The start time for #{event.name} could not be shifted from #{flexible_format(old_start_time, new_start_time)} to #{flexible_format(new_start_time, old_start_time)}. "
      when shift_seconds == 0
        "The new start time for #{event.name} was #{flexible_format(new_start_time, old_start_time)}, unchanged from the old start time. "
      else
        "The start time for #{event.name} was shifted #{shift_direction} " +
            "from #{flexible_format(old_start_time, new_start_time)} to #{flexible_format(new_start_time, old_start_time)}. " +
            "All related scheduled start times and split times were shifted #{shift_direction} by the same amount."
      end
    end
  end
end
