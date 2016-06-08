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

end