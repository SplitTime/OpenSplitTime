# frozen_string_literal: true

module Interactors
  class StartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts, current_user_id)
      new(efforts, current_user_id).perform!
    end

    def initialize(efforts, current_user_id)
      @efforts = efforts
      @current_user_id = current_user_id
      @errors = []
      @saved_split_times = []
    end

    def perform!
      SplitTime.transaction do
        efforts.each { |effort| start_effort(effort) }
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :efforts, :current_user_id, :errors, :saved_split_times

    def start_effort(effort)
      return if effort.split_times.any?(&:start?)
      split_time = SplitTime.new(effort_id: effort.id,
                                 time_point: TimePoint.new(1, start_split_id, SubSplit::IN_BITKEY),
                                 time_from_start: 0,
                                 created_by: current_user_id)
      if split_time.save
        saved_split_times << split_time
      else
        errors << resource_error_object(split_time)
      end
    end

    def start_split_id
      @start_split_id ||= efforts.first.event.start_split.id
    end

    def response_message
      errors.present? ? "No efforts were started" : "Started #{pluralize(saved_split_times.size, 'effort')}"
    end
  end
end
