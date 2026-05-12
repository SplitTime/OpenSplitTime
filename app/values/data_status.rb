class DataStatus
  LIMIT_FACTORS = { terrain: { low_bad: 0.3, low_questionable: 0.4, high_questionable: 2.2, high_bad: 3.0 },
                    stats: { low_bad: 0.4, low_questionable: 0.6, high_questionable: 1.7, high_bad: 2.5 },
                    focused: { low_bad: 0.5, low_questionable: 0.7, high_questionable: 1.5, high_bad: 2.2 },
                    zero_start: { low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0 },
                    in_aid: { low_bad: 0, low_questionable: 0, high_questionable: 60, high_bad: 100 } }
                  .with_indifferent_access

  LIMIT_TYPE_ARRAY = LIMIT_FACTORS.keys.map(&:to_sym)
  LIMIT_ARRAY = LIMIT_FACTORS[LIMIT_TYPE_ARRAY.first].keys.map(&:to_sym)
  TYPICAL_TIME_IN_AID = 15.minutes

  # Returns the worst (most-severe) status across the array. Nil entries
  # represent unknown status and are treated as worse than "good"/"confirmed"
  # but better than "questionable"/"bad".
  def self.worst(status_array)
    return nil if status_array.blank?

    string_array = status_array.map { |s| s&.to_s }
    return "bad" if string_array.include?("bad")
    return "questionable" if string_array.include?("questionable")
    return nil if string_array.include?(nil)
    return "good" if string_array.include?("good")

    "confirmed"
  end

  def self.determine(limits, seconds)
    return nil unless limits.present? && seconds

    if (seconds < limits[:low_bad]) | (seconds > limits[:high_bad])
      "bad"
    elsif (seconds < limits[:low_questionable]) | (seconds > limits[:high_questionable])
      "questionable"
    else
      "good"
    end
  end

  def self.reason_for(limits, seconds)
    return nil unless limits.present? && seconds
    return "segment time too fast" if seconds < limits[:low_questionable]
    return "segment time too slow" if seconds > limits[:high_questionable]

    nil
  end

  def self.limits(typical_time, type)
    return nil unless typical_time && type
    raise ArgumentError, "type '#{type}' is not recognized" unless LIMIT_TYPE_ARRAY.include?(type.to_sym)

    typical_time += TYPICAL_TIME_IN_AID if type == :in_aid
    LIMIT_ARRAY.index_with { |limit| (typical_time * LIMIT_FACTORS[type][limit]).to_i }
  end
end
