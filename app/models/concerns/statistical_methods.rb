module StatisticalMethods
  extend ActiveSupport::Concern

  module ClassMethods

    def low_and_high_params(data_set)
      baseline_median = data_set.median
      return nil unless baseline_median
      data_set.keep_if { |v| (v > (baseline_median / 2)) && (v < (baseline_median * 2))}
      return nil unless data_set.count > 7
      low3std = data_set.mean - (3 * data_set.standard_deviation)
      low2std = data_set.mean - (2 * data_set.standard_deviation)
      high2std = data_set.mean + (2 * data_set.standard_deviation)
      high3std = data_set.mean + (3 * data_set.standard_deviation)
      return low3std, low2std, high2std, high3std
    end

  end
end
