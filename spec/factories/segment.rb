FactoryGirl.define do
  factory :segment, class: Segment do
    skip_create
    ignore do
      id 0
      begin_point TimePoint.new(1, 1001, 1)
      end_point TimePoint.new(1, 1001, 1)
      begin_lap_split LapSplit.new(1, Split.new(id: 0, course_id: 10, distance_from_start: 1000))
      end_lap_split LapSplit.new(1, Split.new(id: 0, course_id: 10, distance_from_start: 1000))
    end
    initialize_with { new(args) }

    args do
      {begin_point: begin_point,
       end_point: end_point,
       begin_lap_split: begin_lap_split,
       end_lap_split: end_lap_split}
    end
  end
end