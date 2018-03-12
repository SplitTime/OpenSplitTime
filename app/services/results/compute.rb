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
      @podium_size = args[:podium_size]
      @method = args[:method]
      @used_efforts = Set.new
    end

    def perform
      categories.map { |category| fill(category) }
    end

    private

    attr_reader :efforts, :categories, :podium_size, :method

    def fill(category)
      category.efforts = available_efforts.select { |effort| attributes_match(category, effort) }.first(podium_size)
      category.efforts.each { |effort| used_efforts << effort }
      category
    end

    def attributes_match(category, effort)
      category.genders.include?(effort.gender) && category.age_range.include?(effort.age)
    end

    def available_efforts
      strict? ? efforts : efforts.reject { |effort| used_efforts.include?(effort) }
    end

    def strict?
      method == :strict
    end
  end
end
