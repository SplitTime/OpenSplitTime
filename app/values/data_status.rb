class DataStatus

  def self.get_lowest_data_status(status_array)
    case
      when status_array.include?('bad')
        :bad
      when status_array.include?('questionable')
        :questionable
      when status_array.include?(nil)
        nil
      when status_array.include?('good')
        :good
      else
        :confirmed
    end
  end

end