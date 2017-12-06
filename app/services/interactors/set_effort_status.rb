module Interactors
  class SetEffortStatus

    def self.perform(effort, options = {})
      new(effort, options).perform
    end

    def initialize(effort, options = {})
      ArgsValidator.validate(subject: effort, subject_class: Effort, params: options, exclusive: [:times_container], class: self)
      @effort = effort
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    end

    def perform
      unconfirmed_split_times.each do |split_time|
        Interactors::SetSplitTimeStatus.perform(split_time, effort: effort, times_container: times_container)
      end
      set_effort_data_status
      Interactors::Response.new([], '', changed_resources)
    end

    private

    attr_reader :effort, :times_container
    delegate :lap_splits, to: :effort

    def set_effort_data_status
      effort.data_status = ordered_split_times.map(&:data_status_numeric).push(Effort.data_statuses[:good]).compact.min
    end

    def changed_resources
      changed_effort + changed_split_times
    end

    def changed_effort
      [effort].select(&:changed?)
    end

    def changed_split_times
      ordered_split_times.select(&:changed?)
    end

    def unconfirmed_split_times
      ordered_split_times.reject(&:confirmed?)
    end

    def ordered_split_times
      effort.ordered_split_times.reject(&:destroyed?)
    end
  end
end
