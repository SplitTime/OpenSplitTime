# frozen_string_literal: true

module Results
  class Templates
    def self.find(template_name)
      all[template_name]
    end

    def self.all
      {ramble:
           Results::Template.new(name: 'Ramble',
                                 method: :inclusive,
                                 podium_size: 3,
                                 categories: [:men_overall, :women_overall, :men_masters, :women_masters,
                                  :men_under_20, :women_under_20, :men_20s, :women_20s,
                                  :men_30s, :women_30s, :men_40s, :women_40s,
                                  :men_50s, :women_50s, :men_60s, :women_60s]
                                     .map { |name| Results::Categories.find(name) }),

       overall_30s_40s_50s_seniors:
           Results::Template.new(name: 'Overall, 30s, 40s, 50s, Seniors',
                                 method: :inclusive,
                                 podium_size: 3,
                                 categories: [:men_overall, :women_overall, :men_under_30, :women_under_30,
                                  :men_30s, :women_30s, :men_40s, :women_40s,
                                  :men_50s, :women_50s, :men_seniors, :women_seniors]
                                     .map { |name| Results::Categories.find(name) }),

       blue_sky:
           Results::Template.new(name: 'Blue Sky',
                                 method: :inclusive,
                                 podium_size: 3,
                                 categories: [:men_overall, :women_overall, :men_under_40, :women_under_40,
                                  :men_40s_masters, :women_40s_masters, :men_grandmasters, :women_grandmasters]
                                     .map { |name| Results::Categories.find(name) }),

       masters_and_grandmasters:
           Results::Template.new(name: 'Masters and Grandmasters',
                                 method: :inclusive,
                                 podium_size: 3,
                                 categories: [:men_overall, :women_overall, :men_40s_masters, :women_40s_masters,
                                  :men_grandmasters, :women_grandmasters]
                                     .map { |name| Results::Categories.find(name) }),

       nighthawks_snowshoe:
           Results::Template.new(name: 'Nighthawks Snowshoe',
                                 method: :inclusive,
                                 point_system: [16, 12, 9, 7, 6, 5, 4, 3, 2, 1],
                                 categories: [:boys_12_and_under, :girls_12_and_under, :boys_13_to_16, :girls_13_to_16,
                                  :men_17_to_39, :women_17_to_39, :men_40s_masters, :women_40s_masters,
                                  :men_grandmasters, :women_grandmasters]
                                     .map { |name| Results::Categories.find(name) }),

       nighthawks_ski:
           Results::Template.new(name: 'Nighthawks Ski',
                                 method: :inclusive,
                                 point_system: [16, 12, 9, 7, 6, 5, 4, 3, 2, 1],
                                 categories: [:boys_16_and_under, :girls_16_and_under,
                                  :men_17_to_39, :women_17_to_39, :men_40s_masters, :women_40s_masters,
                                  :men_grandmasters, :women_grandmasters]
                                     .map { |name| Results::Categories.find(name) }),

       simple:
           Results::Template.new(name: 'Simple',
                                 method: :inclusive,
                                 podium_size: 3,
                                 categories: [:men_overall, :women_overall]
                                     .map { |name| Results::Categories.find(name) })
      }.with_indifferent_access
    end

    def self.keys_and_names
      all.map { |key, template| [key, template.name] }
    end
  end
end
