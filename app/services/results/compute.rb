# frozen_string_literal: true

module Results
  class Compute
    def self.perform(args)
      new(args).perform
    end

    attr_reader :used_efforts

    def initialize(args)
      @efforts = args[:efforts].to_a.sort_by(&:overall_rank)
      @categories = args[:categories]
      @podium_size = args[:podium_size] || efforts.size
      @method = args[:method]
      @point_system = args[:point_system] || []
      @used_efforts = Set.new
    end

    def perform
      categories.map { |category| fill(category) }
    end

    private

    attr_reader :efforts, :categories, :podium_size, :method, :point_system

    def fill(category)
      category.efforts = available_efforts.select { |effort| attributes_match(category, effort) }.first(podium_size)
      category.efforts.each_with_index do |effort, i|
        effort.points = point_system[i] || 0
        used_efforts << effort
      end
      category
    end

    def attributes_match(category, effort)
      (category.all_genders? || effort.gender.in?(category.genders)) &&
          (category.all_ages? || effort.age.in?(category.age_range))
    end

    def available_efforts
      strict? ? efforts : efforts.reject { |effort| used_efforts.include?(effort) }
    end

    def strict?
      method == :strict
    end
  end
end
