# frozen_string_literal: true

module Results
  class Templates
    def self.find(template_name)
      all[template_name]
    end

    def self.all
      {ramble: Results::Template.new('Ramble', :inclusive, 3,
                                     [:men_overall, :women_overall, :men_masters, :women_masters,
                                      :men_under_20, :women_under_20, :men_20s, :women_20s,
                                      :men_30s, :women_30s, :men_40s, :women_40s,
                                      :men_50s, :women_50s, :men_60s, :women_60s]
                                         .map { |name| Results::Categories.find(name) }),
       blue_sky: Results::Template.new('Blue Sky', :inclusive, 3,
                                       [:men_overall, :women_overall, :men_under_40, :women_under_40,
                                        :men_40s_masters, :women_40s_masters, :men_grandmasters, :women_grandmasters]
                                           .map { |name| Results::Categories.find(name) }),
       simple: Results::Template.new('Simple', :inclusive, 3,
                                     [:men_overall, :women_overall]
                                         .map { |name| Results::Categories.find(name) })
      }.with_indifferent_access
    end

    def self.keys_and_names
      all.map { |key, template| [key, template.name] }
    end
  end
end
