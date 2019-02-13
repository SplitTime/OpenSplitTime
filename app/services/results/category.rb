# frozen_string_literal: true

module Results
  Category = Struct.new(:name, :genders, :low_age, :high_age, :efforts, keyword_init: true) do

    INF = 1.0/0

    def age_range
      (low_age || 0)..(high_age || INF)
    end

    def all_ages?
      age_range == (0..INF)
    end

    def all_genders?
      genders.sort == %w[female male]
    end
  end
end
