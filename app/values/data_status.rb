class DataStatus

  def self.worst(status_array)
    status_array.map! { |status| status.try(:to_s) }
    case
      when status_array.count < 1
        nil
      when status_array.include?('bad')
        'bad'
      when status_array.include?('questionable')
        'questionable'
      when status_array.include?(nil)
        nil
      when status_array.include?('good')
        'good'
      when status_array.all? { |status| status == 'confirmed'}
        'confirmed'
      else
        nil
    end
  end
  
  def self.determine(limits, time_from_start)
    low_bad = limits[0]
    low_questionable = limits[1]
    high_questionable = limits[2]
    high_bad = limits[3]
    return nil unless time_from_start
    if (time_from_start < low_bad) | (time_from_start > high_bad)
      'bad'
    elsif (time_from_start < low_questionable) | (time_from_start > high_questionable)
      'questionable'
    else
      'good'
    end
  end

end