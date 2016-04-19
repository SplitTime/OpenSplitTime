class Admin

  def self.analyze_times_by_effort
    Event.all.each do |event|
      next if event.efforts.count < 1
      event.efforts.all.each do |effort|
        effort.set_data_status_horizontal
      end
    end
  end

  def self.analyze_times_by_split
    Split.all.each do |split|
      split.analyze_all_times
    end
  end

end
