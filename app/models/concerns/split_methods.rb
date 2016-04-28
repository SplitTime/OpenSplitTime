module SplitMethods
  extend ActiveSupport::Concern

  def segment_name(split1, split2) # TODO make more flexible for time in aid etc.
    split1.base_name == split2.base_name ?
        [split1.name, split2.name].join(' to ') :
        [split1.base_name, split2.base_name].join(' to ')
  end

  def segment_distance(split1, split2 = nil)
    if split2.nil?
      split1.start? ? 0 : split1.distance_from_start - previous_split(split1).distance_from_start
    else
      (split2.distance_from_start - split1.distance_from_start)
    end
  end

  def previous_split(split)
    return nil if split.start?
    ordered_splits = splits.ordered
    ordered_splits[ordered_splits.index(split) - 1]
  end

  def segment_time_data_array(split1, split2 = nil)
    # Returns a hash of effort_ids and segment times:
    # split2 - split1 if split2 or split1 - prior split if split2.nil
    return nil if split1.nil?
    return {0 => 0} if split1.start?
    end_split = split2.nil? ? split1 : split2
    start_split = split2.nil? ? previous_split(end_split) : split1
    return nil if start_split.nil?
    start_times = start_split.time_hash
    end_times = end_split.time_hash
    start_times.keep_if { |k,_| end_times.keys.include?(k) }
    end_times.keep_if { |k,_| start_times.keys.include?(k) }
    end_times.merge(start_times) { |_, x, y| x - y }
  end

  def waypoint_groups
    result = []
    splits.find_each do |split|
      result << waypoint_group(split).map(&:id)
    end
    result.uniq
  end

  def waypoint_groups_without_start
    result = waypoint_groups
    result.shift
    result
  end

  def waypoint_group(split)
    splits.where(distance_from_start: split.distance_from_start).order(:sub_order)
  end

  def base_splits
    splits.where(sub_order: 0).order(:distance_from_start)
  end

  def ordered_splits
    splits.ordered
  end

  def ordered_splits_without_start
    splits.waypoint.union(splits.finish).ordered
  end

  def split_ids
    splits.ordered.map &:id
  end

  module ClassMethods

  end
end
