class DataStatus

  LIMIT_FACTORS = {terrain: {low_bad: 0.2, low_questionable: 0.3, high_questionable: 3.5, high_bad: 5.0},
                   stats: {low_bad: 0.3, low_questionable: 0.4, high_questionable: 2.0, high_bad: 3.0},
                   focused: {low_bad: 0.4, low_questionable: 0.6, high_questionable: 1.6, high_bad: 2.2},
                   start: {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0},
                   in_aid: {low_bad: 0, low_questionable: 0, high_questionable: 10, high_bad: 100}}
                      .with_indifferent_access

  LIMIT_TYPE_ARRAY = LIMIT_FACTORS.keys.map(&:to_sym)
  LIMIT_ARRAY = LIMIT_FACTORS[LIMIT_TYPE_ARRAY.first].keys.map(&:to_sym)

  # Bad and questionable data_status enums are 0 and 1, respectively. Good and confirmed are 2 and 3.
  # Unknown data_status is nil. To sort properly, this algorithm treats nil as 1.5.
  # TODO Fix this by migrating good and confirmed to 3 and 4, respectively,
  # make a new 'unknown' data_status enum as 2, and set the default for new records to 2.

  def self.worst(status_array)
    return nil if status_array.empty?
    worst_numeric = status_array.map { |status| status ? SplitTime.data_statuses[status] : 1.5 }.min
    worst_numeric == 1.5 ? nil : SplitTime.data_statuses.invert[worst_numeric]
  end

  def self.determine(limits, seconds)
    return nil unless seconds
    if (seconds < limits[:low_bad]) | (seconds > limits[:high_bad])
      'bad'
    elsif (seconds < limits[:low_questionable]) | (seconds > limits[:high_questionable])
      'questionable'
    else
      'good'
    end
  end

  def self.limits(typical_time, type)
    raise ArgumentError, "type '#{type}' is not recognized" unless LIMIT_TYPE_ARRAY.include?(type.to_sym)
    LIMIT_ARRAY.map { |limit| [limit, typical_time * LIMIT_FACTORS[type][limit]] }.to_h
  end
end