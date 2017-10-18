module Interactors
  class AdjustEventStartTime
    include Interactors::Errors
    include BackgroundNotifiable

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      @event = args[:event]
      @new_start_time = args[:new_start_time]
      @background_channel = args[:background_channel]
      @errors = []
    end

    def perform!
      unless start_time_shift.zero?
        ActiveRecord::Base.transaction do
          errors << resource_error_object(event) unless event.update(start_time: new_start_time)
          update_split_times unless errors.present?
          raise ActiveRecord::Rollback if errors.present?
        end
      end
      report_interactor_response(response)
      response
    end

    private

    attr_reader :event, :new_start_time, :background_channel, :errors

    def update_split_times
      total_count = non_start_split_times.size
      non_start_split_times.each.with_index(1) do |st, index|
        st.time_from_start -= start_time_shift
        errors << resource_error_object(st) unless st.save
        report_progress(action: 'updated', resource: 'split time', current: index, total: total_count)
      end
    end

    def non_start_split_times
      @non_start_split_times ||= event.split_times.includes(:split).where.not(splits: {kind: :start})
    end

    def start_time_shift
      @start_time_shift ||= Time.parse(new_start_time) - event.start_time
    end

    def response
      Interactors::Response.new(errors, message, {})
    end

    def message
      if errors.present?
        "Unable to update event start time for #{event}. "
      elsif start_time_shift.zero?
        "Start time for #{event} was not changed. "
      else
        "Start time for #{event} was changed from #{event.start_time_was} to #{event.start_time} and non-start split times were adjusted #{adjustment_amount} to maintain absolute times. "
      end
    end

    def adjustment_amount
      start_time_shift.positive? ? "backward by #{start_time_shift} seconds" : "forward by #{start_time_shift.abs} seconds"
    end
  end
end
