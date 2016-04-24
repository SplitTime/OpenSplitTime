module StatisticalMethods
  extend ActiveSupport::Concern

  module ClassMethods

    def low_and_high_params(data_set)
      baseline_median = data_set.median
      return nil unless baseline_median
      data_set.keep_if { |v| (v > (baseline_median / 2)) && (v < (baseline_median * 2))}
      return nil unless data_set.count > 7
      low4std = data_set.mean - (4 * data_set.standard_deviation)
      low3std = data_set.mean - (3 * data_set.standard_deviation)
      high3std = data_set.mean + (3 * data_set.standard_deviation)
      high5std = data_set.mean + (5 * data_set.standard_deviation)
      return low4std, low3std, high3std, high5std
    end

  end
end
