# frozen_string_literal: true

module Interactors
  class UnstartEfforts
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts)
      new(efforts).perform!
    end

    def initialize(efforts)
      @efforts = efforts
      @errors = []
      @destroyed_split_times = []
      validate_efforts
    end

    def perform!
      SplitTime.transaction do
        efforts.each { |effort| unstart_effort(effort) }
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, response_message)
    end

    private

    attr_reader :efforts, :errors, :destroyed_split_times

    def unstart_effort(effort)
      effort.update(checked_in: false)
      starting_split_time = effort.starting_split_time
      return unless starting_split_time

      if starting_split_time.destroy
        destroyed_split_times << starting_split_time
      else
        errors << resource_error_object(starting_split_time)
      end
    end

    def response_message
      errors.present? ? "No efforts were changed to DNS" : "Changed #{pluralize(destroyed_split_times.size, 'effort')} to DNS"
    end

    def validate_efforts
      efforts.select(&:beyond_start?).each do |effort|
        errors << cannot_unstart_error(effort)
      end
    end
  end
end
