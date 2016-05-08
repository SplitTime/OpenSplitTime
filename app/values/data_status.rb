class DataStatus

  def self.get_lowest_data_status(status_array)
    status_array.map! { |status| status.try(:to_sym) }
    case
      when status_array.count < 1
        nil
      when status_array.include?(:bad)
        :bad
      when status_array.include?(:questionable)
        :questionable
      when status_array.include?(nil)
        nil
      when status_array.include?(:good)
        :good
      else
        nil
    end
  end

end