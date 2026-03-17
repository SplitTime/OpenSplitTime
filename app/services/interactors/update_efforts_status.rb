module Interactors
  class UpdateEffortsStatus
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(efforts, **)
      new(efforts, **).perform!
    end

    def initialize(efforts, times_container: nil, calc_model: nil)
      @efforts = Array.wrap(efforts)
      @times_container = times_container || SegmentTimesContainer.new(calc_model: calc_model || :stats)
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        Persist::BulkUpdateAll.perform!(SplitTime, changed_split_times, update_fields: :data_status)
        Persist::SaveRecords.perform!(Effort, changed_efforts, update_fields: :data_status)
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
      changed_resources.grep(Effort)
    end

    def changed_split_times
      changed_resources.grep(SplitTime)
    end

    def status_responses
      @status_responses ||= efforts.map { |effort| Interactors::SetEffortStatus.perform(effort, times_container: times_container) }
    end

    def message
      if errors.empty?
        return "Everything up to date." unless changed_efforts.present? || changed_split_times.present?

        updated_efforts_string = changed_efforts.present? ? pluralize(changed_efforts.size, "effort") : nil
        updated_split_times_string = if changed_split_times.present?
                                       pluralize(changed_split_times.size,
                                                 "split time")
                                     end
        "Updated status for #{[updated_efforts_string, updated_split_times_string].compact.join(' and ')}. "
      else
        "Could not update status for the provided efforts. "
      end
    end
  end
end
