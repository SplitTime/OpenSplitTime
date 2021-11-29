FactoryBot.define do
  factory :segment, class: Segment do
    skip_create
    transient do
      begin_lap { 1 }
      end_lap { 1 }
      begin_split { Split.new(course_id: 10, distance_from_start: 1000) }
      end_split { Split.new(course_id: 10, distance_from_start: 1000) }
      begin_in_out { 'in' }
      end_in_out { 'in' }
      order_control { true }
    end

    initialize_with { new(args) }

    args do
      {begin_point: TimePoint.new(begin_lap, begin_split.id, SubSplit.bitkey(begin_in_out.to_s)),
       end_point: TimePoint.new(end_lap, end_split.id, SubSplit.bitkey(end_in_out.to_s)),
       begin_lap_split: LapSplit.new(begin_lap, begin_split),
       end_lap_split: LapSplit.new(end_lap, end_split),
       order_control: order_control}
    end
  end
end