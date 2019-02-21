# frozen_string_literal: true

module Results
  class Compute
    def self.perform(args)
      new(args).perform
    end

    attr_reader :used_efforts

    def initialize(args)
      # efforts must be pre-sorted in the desired order
      @efforts = args[:efforts]
      @template = args[:template]
      @used_efforts = Set.new
    end

    def perform
      categories.map(&method(:fill))
    end

    private

    attr_reader :sort_attribute, :efforts, :template
    delegate :aggregation_method, to: :template

    def podium_size
      template.podium_size || efforts.size
    end

    def point_system
      template.point_system || []
    end

    def categories
      template.results_categories
    end

    def fill(category)
      category.efforts = available_efforts.select { |effort| attributes_match(category, effort) }.first(podium_size)
      category.efforts.each_with_index do |effort, i|
        effort.points = point_system[i] || 0
        used_efforts << effort
      end
      category
    end

    def attributes_match(category, effort)
      # Check for all_ages? is necessary to properly sort overall categories
      # when age is not provided.
      effort.gender.in?(category.genders) &&
          (category.all_ages? || effort.template_age.in?(category.age_range))
    end

    def available_efforts
      strict? ? efforts : efforts.reject { |effort| used_efforts.include?(effort) }
    end

    def strict?
      aggregation_method == :strict
    end
  end
end
