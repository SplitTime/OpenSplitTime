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
          men_seniors: Results::Category.new('Senior Grandmasters Men (60+)', %w[male], 60),
          women_seniors: Results::Category.new('Senior Grandmasters Women (60+)', %w[female], 60),
          boys_12_and_under: Results::Category.new('Boys 12 and Under', %w[male], nil, 12),
          girls_12_and_under: Results::Category.new('Girls 12 and Under', %w[female], nil, 12),
          boys_13_to_16: Results::Category.new('Boys 13 to 16', %w[male], 13, 16),
          girls_13_to_16: Results::Category.new('Girls 13 to 16', %w[female], 13, 16),
          boys_16_and_under: Results::Category.new('Boys 16 and Under', %w[male], nil, 16),
          girls_16_and_under: Results::Category.new('Girls 16 and Under', %w[female], nil, 16),
          men_under_20: Results::Category.new('Under 20 Men', %w[male], nil, 19),
          women_under_20: Results::Category.new('Under 20 Women', %w[female], nil, 19),
          men_13_to_39: Results::Category.new('13 to 39 Men', %w[male], 13, 39),
          women_13_to_39: Results::Category.new('13 to 39 Women', %w[female], 13, 39),
          men_17_to_39: Results::Category.new('17 to 39 Men', %w[male], 17, 39),
          women_17_to_39: Results::Category.new('17 to 39 Women', %w[female], 17, 39),
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
          men_under_30: Results::Category.new('Under 30 Men', %w[male], nil, 29),
          women_under_30: Results::Category.new('Under 30 Women', %w[female], nil, 29),
          men_under_40: Results::Category.new('Under 40 Men', %w[male], nil, 39),
          women_under_40: Results::Category.new('Under 40 Women', %w[female], nil, 39)
      }.with_indifferent_access
    end
  end
end
