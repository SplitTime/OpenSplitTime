module Results
  class ReportTimeDistribution
    def self.perform(event_group)
      new(event_group).perform
    end

    def initialize(event_group)
      @event_group = event_group
    end

    def perform
      split_times.map(&:day_and_time).group_by { |datetime| [datetime.to_date, datetime.hour] }.transform_values(&:size)
    end

    private

    attr_reader :event_group

    def efforts
      Effort.includes(event: :event_group).where(event: event_group.events)
    end

    def split_times
      SplitTime.includes(effort: {event: :event_group}).where(effort: efforts)
    end
  end
end
