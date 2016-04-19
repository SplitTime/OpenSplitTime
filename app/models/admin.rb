class Admin

  def self.flag_negative_split_times
    Event.all.each do |event|
      next if event.efforts.count < 1
      event.efforts.all.each do |effort|
        next if effort.split_times.count < 1
        ordered_group = effort.ordered_split_times.to_a
        ordered_group[0].update(data_status: 'questionable') if ordered_group[0].time_from_start != 0
        next if ordered_group.count < 2
        (1..ordered_group.count - 1).each do |i|
          split_time = ordered_group[i]
          if split_time.time_from_start - ordered_group[i - 1].time_from_start < 0
            split_time.update(data_status: 'bad')
            effort.update(data_status: 'bad')
          end
        end
      end
    end
  end

  def self.flag_unlikely_split_times
    Split.all.each do |split|
      next if split.split_times.count < 10
      time_data_set = split.split_times.pluck(:time_from_start)
      low_permitted = time_data_set.mean - (5 * time_data_set.standard_deviation)
      high_permitted = time_data_set.mean + (5 * time_data_set.standard_deviation)
      low_questioned = time_data_set.mean - (3 * time_data_set.standard_deviation)
      high_questioned = time_data_set.mean + (3 * time_data_set.standard_deviation)
      split.split_times.each do |split_time|
        if (split_time.time_from_start < low_permitted) | (split_time.time_from_start > high_permitted)
          split_time.update(data_status: 'bad')
          split_time.effort.update(data_status: 'bad')
        elsif (split_time.time_from_start < low_questioned) | (split_time.time_from_start > high_questioned)
          split_time.update(data_status: 'questionable')
          split_time.effort.update(data_status: 'questionable')
        end
      end
    end
  end

end
