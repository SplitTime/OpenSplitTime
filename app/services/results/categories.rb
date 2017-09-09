module Results
  class Categories
    def self.find(category_name)
      all.find { |category| category.name == category_name }
    end

    def self.all
      [
          Results::Category.new('Overall', %w[male female]),
          Results::Category.new('Overall Men', %w[male]),
          Results::Category.new('Overall Women', %w[female]),
          Results::Category.new('Masters Men', %w[male], 40),
          Results::Category.new('Masters Women', %w[female], 40),
          Results::Category.new('Under 20 Men', %w[male], nil, 19),
          Results::Category.new('Under 20 Women', %w[female], nil, 19),
          Results::Category.new('20 to 29 Men', %w[male], 20, 29),
          Results::Category.new('20 to 29 Women', %w[female], 20, 29),
          Results::Category.new('30 to 39 Men', %w[male], 30, 39),
          Results::Category.new('30 to 39 Women', %w[female], 30, 39),
          Results::Category.new('40 to 49 Men', %w[male], 40, 49),
          Results::Category.new('40 to 49 Women', %w[female], 40, 49),
          Results::Category.new('50 to 59 Men', %w[male], 50, 59),
          Results::Category.new('50 to 59 Women', %w[female], 50, 59),
          Results::Category.new('60 to 69 Men', %w[male], 60, 69),
          Results::Category.new('60 to 69 Women', %w[female], 60, 69)
      ]
    end
  end
end
