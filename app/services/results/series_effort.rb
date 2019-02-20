# frozen_string_literal: true

module Results
  class SeriesEffort
    attr_reader :person
    attr_accessor :points # For duck typing only
    delegate :full_name, to: :person
    delegate :age, :gender, :bio_historic, :flexible_geolocation, to: :effort

    def initialize(args)
      @person = args[:person]
      @efforts = args[:efforts]
      validate_setup
    end

    def event_names
      efforts.map(&:event_name)
    end

    def final_times
      efforts.map(&:final_time_from_start)
    end

    def indexed_times
      indexed_efforts.transform_values(&:final_time_from_start)
    end

    def total_time
      final_times.sum if final_times.all?(&:present?)
    end
    
    def final_points
      efforts.map(&:points)
    end

    def indexed_points
      indexed_efforts.transform_values(&:points)
    end

    def total_points
      final_points.compact.sum
    end

    private

    attr_reader :efforts

    def indexed_efforts
      @indexed_efforts ||= efforts.index_by(&:event_id)
    end

    def effort
      efforts.last
    end

    def validate_setup
      raise ArgumentError, "One or more efforts is not reconciled" unless efforts.all?(&:person_id)
      raise ArgumentError, "One or more efforts does not match the provided person" unless efforts.all? { |effort| effort.person_id == person.id }
    end
  end
end
