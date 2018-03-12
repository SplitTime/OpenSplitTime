# frozen_string_literal: true

module Results
  Category = Struct.new(:name, :genders, :low_age, :high_age, :efforts) do

    INF = 1.0/0

    def age_range
      (low_age || 0)..(high_age || INF)
    end
  end
end
