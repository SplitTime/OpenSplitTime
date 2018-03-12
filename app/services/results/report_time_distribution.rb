# frozen_string_literal: true

module Results
  class ReportTimeDistribution
    def self.perform(event_group)
      new(event_group).perform
    end

    def initialize(event_group)
      @event_group = event_group
    end

    def perform
      split_times.map(&:day_and_time).group_by { |datetime| datetime.strftime('%Y-%m-%d %H')+ ':00' }.transform_values(&:size).sort
    end

    private

    attr_reader :event_group

    def split_times
      SplitTime.includes(effort: {event: :event_group}).where(effort: {event: {event_groups: {id: event_group}}})
    end
  end
end
