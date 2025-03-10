module Interactors
  class BulkDestroyEfforts
    include ::ActionView::Helpers::TextHelper
    include ::Interactors::Errors

    def self.perform!(efforts)
      new(efforts).perform!
    end

    def initialize(efforts)
      @efforts = efforts
      @effort_initial_count = efforts.count
      @errors = []
    end

    def perform!
      ::ActiveRecord::Base.transaction do
        nullify_raw_times
        delete_split_times
        destroy_efforts
        raise ::ActiveRecord::Rollback if errors.present?
      end
      ::Interactors::Response.new(errors, message, {})
    end

    private

    attr_reader :efforts, :effort_initial_count, :errors

    def nullify_raw_times
      raw_times = ::RawTime.where(split_time: split_times)
      raw_times.update_all(split_time_id: nil)
    end

    def delete_split_times
      split_times.delete_all
    rescue ::ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    # To ensure dependents are properly handled, use destroy_all instead of delete_all
    def destroy_efforts
      efforts.destroy_all
    rescue ActiveRecord::ActiveRecordError => e
      errors << active_record_error(e)
    end

    def split_times
      @split_times ||= SplitTime.where(effort: efforts)
    end

    def message
      if errors.present?
        "Unable to delete efforts"
      elsif effort_initial_count.zero?
        "No efforts were provided"
      else
        "Deleted #{pluralize(effort_initial_count, 'effort')}"
      end
    end
  end
end
