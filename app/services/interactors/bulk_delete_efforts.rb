# frozen_string_literal: true

module Interactors
  class BulkDeleteEfforts
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts)
      new(efforts).perform!
    end

    def initialize(efforts)
      @efforts = efforts
      @effort_initial_count = efforts.size
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        unlink_live_times
        delete_split_times
        delete_efforts
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message, {})
    end

    private

    attr_reader :efforts, :effort_initial_count, :errors

    def unlink_live_times
      LiveTime.where(split_time_id: split_times.map(&:id)).update_all(split_time_id: nil)
    rescue ActiveRecord::ActiveRecordError => exception
      errors << Interactors::Errors.active_record_error(exception)
    end

    def delete_split_times
      split_times.delete_all
    rescue ActiveRecord::ActiveRecordError => exception
      errors << Interactors::Errors.active_record_error(exception)
    end

    def delete_efforts
      efforts.delete_all
    rescue ActiveRecord::ActiveRecordError => exception
      errors << Interactors::Errors.active_record_error(exception)
    end

    def split_times
      @split_times ||= SplitTime.where(effort_id: efforts.map(&:id))
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
