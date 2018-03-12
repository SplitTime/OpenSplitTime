# frozen_string_literal: true

module Results
  class Categories
    def self.find(category_name)
      all[category_name]
    end

    def self.all
      {
          combined_overall: Results::Category.new('Overall', %w[male female]),
          men_overall: Results::Category.new('Overall Men', %w[male]),
          women_overall: Results::Category.new('Overall Women', %w[female]),
          men_masters: Results::Category.new('Masters Men (40+)', %w[male], 40),
          women_masters: Results::Category.new('Masters Women (40+)', %w[female], 40),
          men_40s_masters: Results::Category.new('Masters Men (40-49)', %w[male], 40, 49),
          women_40s_masters: Results::Category.new('Masters Women (40-49)', %w[female], 40, 49),
          men_grandmasters: Results::Category.new('Grandmasters Men (50+)', %w[male], 50),
          women_grandmasters: Results::Category.new('Grandmasters Women (50+)', %w[female], 50),
          men_under_20: Results::Category.new('Under 20 Men', %w[male], nil, 19),
          women_under_20: Results::Category.new('Under 20 Women', %w[female], nil, 19),
          men_20s: Results::Category.new('20 to 29 Men', %w[male], 20, 29),
          women_20s: Results::Category.new('20 to 29 Women', %w[female], 20, 29),
          men_30s: Results::Category.new('30 to 39 Men', %w[male], 30, 39),
          women_30s: Results::Category.new('30 to 39 Women', %w[female], 30, 39),
          men_40s: Results::Category.new('40 to 49 Men', %w[male], 40, 49),
          women_40s: Results::Category.new('40 to 49 Women', %w[female], 40, 49),
          men_50s: Results::Category.new('50 to 59 Men', %w[male], 50, 59),
          women_50s: Results::Category.new('50 to 59 Women', %w[female], 50, 59),
          men_60s: Results::Category.new('60 to 69 Men', %w[male], 60, 69),
          women_60s: Results::Category.new('60 to 69 Women', %w[female], 60, 69),
          men_under_40: Results::Category.new('Under 40 Men', %w[male], nil, 39),
          women_under_40: Results::Category.new('Under 40 Women', %w[female], nil, 39)
      }.with_indifferent_access
    end
  end
end
