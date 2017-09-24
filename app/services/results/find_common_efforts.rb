module Results
  class FindCommonEfforts

    def self.perform(events)
      new(events).perform
    end

    def initialize(events)
      @events = events
    end

    def perform
      common_efforts.reject { |_, efforts| efforts.size != events.size }
    end

    private

    attr_reader :events

    def common_efforts
      common_person_ids.map { |person_id| [person_id, events.map { |event| find_effort(person_id, event) }] }.to_h
    end

    def common_person_ids
      all_efforts.map { |effort_group| effort_group.map(&:person_id) }.reduce(:&)
    end

    def all_efforts
      @all_efforts ||= events.map { |event| event.efforts.ranked_with_finish_status.select(&:finished?) }
    end

    def find_effort(person_id, event)
      all_efforts.flatten.find { |effort| (effort.person_id == person_id) && (effort.event_id == event.id) }
    end
  end
end
