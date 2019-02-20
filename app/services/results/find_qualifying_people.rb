# frozen_string_literal: true

module Results
  class FindQualifyingPeople

    def self.perform(event_series)
      new(event_series).perform
    end

    def initialize(event_series)
      @event_series = event_series
    end

    def perform
      qualifying_ids_with_efforts.map do |person_id, efforts|
        OpenStruct.new(person: indexed_people[person_id], efforts: efforts)
      end
    end

    private

    attr_reader :event_series
    delegate :events, :absences_permitted, to: :event_series

    def qualifying_ids_with_efforts
      @qualifying_ids_with_efforts ||= efforts_by_person_id.reject { |_, efforts| efforts.size < required_event_count }
    end

    def required_event_count
      @required_event_count ||= events.size - absences_permitted
    end

    def efforts_by_person_id
      events.flat_map { |event| event.efforts.ranked_with_status.select(&:finished?) }.group_by(&:person_id)
    end

    def indexed_people
      @indexed_people ||= Person.find(person_ids).index_by(&:id)
    end

    def person_ids
      qualifying_ids_with_efforts.keys
    end
  end
end
