def lap_splits_and_time_points(event)
  allow_any_instance_of(Event).to receive(:ordered_splits).and_return(event.splits)
  lap_splits = event.required_lap_splits
  time_points = lap_splits.flat_map(&:time_points)
  [lap_splits, time_points]
end
