module StatisticalMethods
  extend ActiveSupport::Concern

  module ClassMethods

    def low_and_high_params(data_set)
      baseline_mean = data_set.mean
      data_set.keep_if { |v| (v > (baseline_mean / 2)) && (v < (baseline_mean * 2))}
      low3std = data_set.mean - (3 * data_set.standard_deviation)
      low2std = data_set.mean - (2 * data_set.standard_deviation)
      high2std = data_set.mean + (2 * data_set.standard_deviation)
      high3std = data_set.mean + (3 * data_set.standard_deviation)
      return low3std, low2std, high2std, high3std
    end

  end
end
