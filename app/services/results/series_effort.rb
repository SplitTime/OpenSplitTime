# frozen_string_literal: true

module Results
  class SeriesEffort
    delegate :full_name, :to_param, to: :person
    delegate :bio_historic, :flexible_geolocation, to: :effort

    def initialize(args)
      @person = args[:person]
      @efforts = args[:efforts]
    end

    def event_names
      efforts.map(&:event_name)
    end

    def final_times
      efforts.map(&:final_time)
    end

    def total_time
      final_times.sum if final_times.all?(&:present?)
    end

    private

    attr_reader :person, :efforts

    def effort
      efforts.last
    end
  end
end
