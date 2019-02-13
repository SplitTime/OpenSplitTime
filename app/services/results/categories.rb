# frozen_string_literal: true

module Results
  class Categories
    def self.find(category_name)
      all[category_name]
    end

    def self.all
      {
          combined_overall: Results::Category.new(name: 'Overall', genders: %w[male female]),
          men_overall: Results::Category.new(name: 'Overall Men', genders: %w[male]),
          women_overall: Results::Category.new(name: 'Overall Women', genders: %w[female]),
          men_masters: Results::Category.new(name: 'Masters Men (40+)', genders: %w[male], low_age: 40),
          women_masters: Results::Category.new(name: 'Masters Women (40+)', genders: %w[female], low_age: 40),
          men_40s_masters: Results::Category.new(name: 'Masters Men (40-49)', genders: %w[male], low_age: 40, high_age: 49),
          women_40s_masters: Results::Category.new(name: 'Masters Women (40-49)', genders: %w[female], low_age: 40, high_age: 49),
          men_grandmasters: Results::Category.new(name: 'Grandmasters Men (50+)', genders: %w[male], low_age: 50),
          women_grandmasters: Results::Category.new(name: 'Grandmasters Women (50+)', genders: %w[female], low_age: 50),
          men_seniors: Results::Category.new(name: 'Senior Grandmasters Men (60+)', genders: %w[male], low_age: 60),
          women_seniors: Results::Category.new(name: 'Senior Grandmasters Women (60+)', genders: %w[female], low_age: 60),
          boys_12_and_under: Results::Category.new(name: 'Boys 12 and Under', genders: %w[male], low_age: nil, high_age: 12),
          girls_12_and_under: Results::Category.new(name: 'Girls 12 and Under', genders: %w[female], low_age: nil, high_age: 12),
          boys_13_to_16: Results::Category.new(name: 'Boys 13 to 16', genders: %w[male], low_age: 13, high_age: 16),
          girls_13_to_16: Results::Category.new(name: 'Girls 13 to 16', genders: %w[female], low_age: 13, high_age: 16),
          boys_16_and_under: Results::Category.new(name: 'Boys 16 and Under', genders: %w[male], low_age: nil, high_age: 16),
          girls_16_and_under: Results::Category.new(name: 'Girls 16 and Under', genders: %w[female], low_age: nil, high_age: 16),
          men_under_20: Results::Category.new(name: 'Under 20 Men', genders: %w[male], low_age: nil, high_age: 19),
          women_under_20: Results::Category.new(name: 'Under 20 Women', genders: %w[female], low_age: nil, high_age: 19),
          men_13_to_39: Results::Category.new(name: '13 to 39 Men', genders: %w[male], low_age: 13, high_age: 39),
          women_13_to_39: Results::Category.new(name: '13 to 39 Women', genders: %w[female], low_age: 13, high_age: 39),
          men_17_to_39: Results::Category.new(name: '17 to 39 Men', genders: %w[male], low_age: 17, high_age: 39),
          women_17_to_39: Results::Category.new(name: '17 to 39 Women', genders: %w[female], low_age: 17, high_age: 39),
          men_20s: Results::Category.new(name: '20 to 29 Men', genders: %w[male], low_age: 20, high_age: 29),
          women_20s: Results::Category.new(name: '20 to 29 Women', genders: %w[female], low_age: 20, high_age: 29),
          men_30s: Results::Category.new(name: '30 to 39 Men', genders: %w[male], low_age: 30, high_age: 39),
          women_30s: Results::Category.new(name: '30 to 39 Women', genders: %w[female], low_age: 30, high_age: 39),
          men_40s: Results::Category.new(name: '40 to 49 Men', genders: %w[male], low_age: 40, high_age: 49),
          women_40s: Results::Category.new(name: '40 to 49 Women', genders: %w[female], low_age: 40, high_age: 49),
          men_50s: Results::Category.new(name: '50 to 59 Men', genders: %w[male], low_age: 50, high_age: 59),
          women_50s: Results::Category.new(name: '50 to 59 Women', genders: %w[female], low_age: 50, high_age: 59),
          men_60s: Results::Category.new(name: '60 to 69 Men', genders: %w[male], low_age: 60, high_age: 69),
          women_60s: Results::Category.new(name: '60 to 69 Women', genders: %w[female], low_age: 60, high_age: 69),
          men_under_30: Results::Category.new(name: 'Under 30 Men', genders: %w[male], low_age: nil, high_age: 29),
          women_under_30: Results::Category.new(name: 'Under 30 Women', genders: %w[female], low_age: nil, high_age: 29),
          men_under_40: Results::Category.new(name: 'Under 40 Men', genders: %w[male], low_age: nil, high_age: 39),
          women_under_40: Results::Category.new(name: 'Under 40 Women', genders: %w[female], low_age: nil, high_age: 39)
      }.with_indifferent_access
    end
  end
end
