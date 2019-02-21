# frozen_string_literal: true

module Results
  class SeriesEffort
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    AGE_DIFFERENCE_THRESHOLD = 2 # years

    attr_reader :person, :efforts
    attr_accessor :points # For duck typing only
    delegate :full_name, to: :person
    delegate :age, :gender, :bio_historic, :flexible_geolocation, :template_age, :to_param, to: :baseline_effort

    validate :verify_effort_consistency
    after_validation :set_template_age

    def initialize(args)
      @person = args[:person]
      @efforts = args[:efforts]
      @event_series = args[:event_series]
    end

    def complete?
      efforts.map(&:event_id).sort == event_series.events.map(&:id).sort
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

    def final_ranks
      efforts.map(&:overall_rank)
    end

    def indexed_ranks
      indexed_efforts.transform_values(&:overall_rank)
    end

    def total_rank
      final_ranks.compact.sum
    end

    private

    attr_reader :event_series

    def indexed_efforts
      @indexed_efforts ||= efforts.index_by(&:event_id)
    end

    def baseline_effort
      @baseline_effort ||= efforts.sort_by(&:actual_start_time).first
    end

    def verify_effort_consistency
      errors.add(:efforts, :unreconciled, message: "cannot be unreconciled") if efforts.any?(&:unreconciled?)
      errors.add(:efforts, :age_and_birthdate_blank, message: "must have an age or birthdate") unless efforts.all?(&:age)
      errors.add(:efforts, :mismatched_with_person, message: "must match the provided person") unless efforts.all? { |e| e.person_id == person.id }
      errors.add(:efforts, :mismatched_genders, message: "must match the provided person's gender") unless efforts.all? { |e| e.gender == person.gender }

      effort_birth_years = efforts.map { |effort| effort.actual_start_time.year - effort.age }.sort
      if (effort_birth_years.last - effort_birth_years.first).abs > AGE_DIFFERENCE_THRESHOLD
        errors.add(:efforts, :mismatched_ages, message: "implied birth years based on effort start time and age are too far apart: #{effort_birth_years.to_sentence}")
      end
    end

    def set_template_age
      efforts.each { |effort| effort.template_age = age }
    end
  end
end
