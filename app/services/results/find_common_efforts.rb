# frozen_string_literal: true

module Results
  class FindCommonEfforts

    def self.perform(events)
      new(events).perform
    end

    def initialize(events)
      @events = events
    end

    def perform
      @perform ||= complete_common_efforts.map { |person_id, efforts| {person_id: person_id, efforts: efforts} }
    end

    private

    attr_reader :events

    def complete_common_efforts
      common_efforts.reject { |_, efforts| efforts.size != events.size }
    end

    def common_efforts
      common_person_ids.map { |person_id| [person_id, events.map { |event| find_effort(person_id, event) }] }
    end

    def common_person_ids
      @common_person_ids ||= indexed_all_efforts.map { |_, effort_group| effort_group.map(&:person_id) }.reduce(:&)
    end

    def indexed_all_efforts
      @indexed_all_efforts ||= events.map { |event| [event.id, event.efforts.ranked_with_finish_status.select(&:finished?)] }.to_h
    end

    def find_effort(person_id, event)
      indexed_all_efforts[event.id].find { |effort| (effort.person_id == person_id) }
    end
  end
end
