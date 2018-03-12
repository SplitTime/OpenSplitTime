# frozen_string_literal: true

module Interactors
  class UpdateEffortsStatus
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts, options = {})
      new(efforts, options).perform!
    end

    def initialize(efforts, options = {})
      ArgsValidator.validate(subject: efforts, params: options, exclusive: [:times_container, :calc_model], class: self)
      @efforts = efforts && Array.wrap(efforts)
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: options[:calc_model] || :stats)
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        Persist::BulkUpdateAll.perform!(SplitTime, changed_split_times, update_fields: :data_status)
        Persist::BulkUpdateAll.perform!(Effort, changed_efforts, update_fields: :data_status)
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message, changed_resources)
    end

    private

    attr_reader :efforts, :times_container, :errors

    def changed_resources
      @changed_resources ||= status_responses.flat_map(&:resources)
    end

    def changed_efforts
      changed_resources.select { |resource| resource.is_a?(Effort) }
    end

    def changed_split_times
      changed_resources.select { |resource| resource.is_a?(SplitTime) }
    end

    def status_responses
      @status_responses ||= efforts.map { |effort| Interactors::SetEffortStatus.perform(effort, times_container: times_container) }
    end

    def message
      if errors.empty?
        "Updated status for #{pluralize(changed_efforts.size, 'effort')} and #{pluralize(changed_split_times.size, 'split time')}. "
      else
        "Could not update status for the provided efforts. "
      end
    end
  end
end
