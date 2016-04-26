module StatisticalMethods
  extend ActiveSupport::Concern

  module ClassMethods

    def low_and_high_params(data_array)
      baseline_median = data_array.median
      return nil unless baseline_median
      data_array.keep_if { |v| (v > (baseline_median / 2)) && (v < (baseline_median * 2)) }
      return nil unless data_array.count > 7
      std = data_array.standard_deviation
      mean = data_array.mean
      low_limit = [mean - (4 * std), 0].max
      low_question = [mean - (3 * std), 0].max
      high_question = mean + (3 * std)
      high_limit = mean + (5 * std)
      return low_limit, low_question, high_question, high_limit
    end

    def compare_and_get_status(value, params)
      return nil unless value
      params << value
      status = case params.sort.index(value)
                 when 0
                   'bad'
                 when 1
                   'questionable'
                 when 2
                   'good'
                 when 3
                   'questionable'
                 else
                   'bad'
               end
      SplitTime.data_statuses[status]
    end

  end
end
