FactoryGirl.define do
  factory :split_times_in_out, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:sub_split_bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 1000, 1100, 2000, 2100, 3000, 3100, 4000, 4100, 5000, 5100, 6000, 6100, 7000, 7100, 8000, 8100, 9000, 9100, 10000].cycle)
    effort
  end

  factory :split_times_in_out_fast, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:sub_split_bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 700, 750, 1400, 1450, 2100, 2150, 2800, 2850, 3500, 3550, 4200, 4250, 4900, 4950, 5600, 5650, 6300, 6350, 7000].cycle)
    effort
  end

  factory :split_times_in_out_slow, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:sub_split_bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 1500, 1600, 3000, 3100, 4500, 4600, 6000, 6100, 7500, 7600, 9000, 9100, 10500, 10600, 12000, 12100, 13500, 13600, 15000].cycle)
    effort
  end

  factory :split_times_in_only, class: SplitTime do
    sequence(:split_id, (201..220).cycle)
    sequence(:sub_split_bitkey, SubSplit::IN_BITKEY)
    sequence(:time_from_start, (0..19).cycle) { |n| n * 1000 }
    effort
  end

  # This factory builds a realistic set of split_times representing a 43+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_1, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:sub_split_bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 11160, 11160, 20880, 21060, 25680, 25740, 35820, 36480, 40740, 40860, 59340, 60480, 69720, 69900, 79320, 80220, 86400, 88200, 98760, 99240, 104100, 104820, 122400, 125400, 140220, 141000, 155040, 155160, 163860].cycle)
    effort
  end
end