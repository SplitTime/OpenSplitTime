module Interactors
  class BulkDeleteEventGroupTimes
    include ActionView::Helpers::TextHelper
    include Interactors::Errors

    def self.perform!(event_group)
      new(event_group).perform!
    end

    def initialize(event_group)
      @event_group = event_group
      @response = Interactors::Response.new([])
    end

    def perform!
      ActiveRecord::Base.transaction do
        delete_raw_times
        delete_effort_segments
        delete_split_times
        set_effort_performance_data
        touch_records
        raise ActiveRecord::Rollback if errors.present?
      end

      set_response_message
      response
    end

    private

    attr_reader :event_group, :response
    attr_accessor :raw_time_count, :split_time_count

    delegate :errors, to: :response, private: true

    def delete_raw_times
      self.raw_time_count = RawTime.where(event_group_id: event_group).delete_all
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def delete_effort_segments
      EffortSegment.where(effort_id: effort_ids).delete_all
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def delete_split_times
      self.split_time_count = SplitTime.where(effort_id: effort_ids).delete_all
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def set_effort_performance_data
      effort_ids.each { |id| Results::SetEffortPerformanceData.perform!(id) }
    end

    def touch_records
      event_group.touch
      event_group.events.each(&:touch)
    end

    def set_response_message
      response.message =
        if errors.present?
          "Unable to delete times"
        else
          "Deleted #{pluralize(raw_time_count, 'raw time')} and #{pluralize(split_time_count, 'split time')}"
        end
    end

    def effort_ids
      @effort_ids ||= Effort.where(event_id: event_group.events).pluck(:id)
    end
  end
end
