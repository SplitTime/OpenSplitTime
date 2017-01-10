FactoryGirl.define do
  factory :split_time do
    bitkey 1
    time_from_start 0
    split
    effort
  end

  factory :split_times_in_out, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 1000, 1100, 2000, 2100, 3000, 3100, 4000, 4100, 5000, 5100, 6000, 6100, 7000, 7100, 8000, 8100, 9000, 9100, 10000].cycle)
    effort
  end

  factory :split_times_in_out_fast, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 700, 750, 1400, 1450, 2100, 2150, 2800, 2850, 3500, 3550, 4200, 4250, 4900, 4950, 5600, 5650, 6300, 6350, 7000].cycle)
    effort
  end

  factory :split_times_in_out_slow, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 1500, 1600, 3000, 3100, 4500, 4600, 6000, 6100, 7500, 7600, 9000, 9100, 10500, 10600, 12000, 12100, 13500, 13600, 15000].cycle)
    effort
  end

  factory :split_times_in_only, class: SplitTime do
    sequence(:split_id, (201..220).cycle)
    sequence(:bitkey, SubSplit::IN_BITKEY)
    sequence(:time_from_start, (0..19).cycle) { |n| n * 1000 }
    effort
  end

  # This factory builds a realistic set of split_times representing a 45+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_0, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 9960, 9960, 20340, 20580, 25500, 25560, 35100, 36540, 40500, 40620, 57839, 58860, 67980, 68280, 78480, 80100, 90480, 91200, 97860, 98160, 104880, 106140, 125460, 125700, 140640, 141360, 154440, 154800, 163200].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 43+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_1, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 11160, 11160, 20880, 21060, 25680, 25740, 35820, 36480, 40740, 40860, 59340, 60480, 69720, 69900, 79320, 80220, 86400, 88200, 98760, 99240, 104100, 104820, 122400, 125400, 140220, 141000, 155040, 155160, 163860].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 41+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_2, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 9780, 9780, 18720, 18840, 23400, 23460, 33060, 33600, 37860, 38220, 52500, 52620, 61800, 62220, 70920, 71880, 81420, 81600, 87420, 87780, 93120, 94740, 112200, 113160, 127560, 127980, 140400, 140400, 148500].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 38+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_3, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 9180, 9180, 17280, 17579, 21540, 21660, 30000, 31080, 34320, 34440, 48240, 49800, 57960, 58319, 65700, 68340, 78540, 79260, 85380, 85500, 90480, 91980, 108660, 109920, 121980, 122580, 132480, 132780, 139260].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 36+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_4, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 8820, 8820, 15960, 16080, 19560, 19620, 27060, 27960, 30900, 30900, 42720, 43500, 51300, 51300, 63000, 63060, 71220, 71400, 76740, 77100, 82800, 84000, 100380, 101940, 113340, 114000, 124200, 124200, 130860].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 35+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_5, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 8520, 8520, 15660, 15720, 19320, 19380, 27300, 27600, 31380, 31800, 44400, 45180, 53520, 54300, 62580, 63600, 73440, 74820, 80940, 81180, 86520, 87540, 100680, 100680, 111180, 111540, 121560, 121560, 127080].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 33+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_6, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 8460, 8460, 16380, 16440, 20460, 20520, 28560, 28860, 32580, 32580, 43980, 44220, 51300, 51300, 58500, 58560, 66899, 67020, 71760, 72060, 76680, 77160, 93360, 94020, 104940, 105420, 115080, 115080, 120720].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 31+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_7, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 7980, 7980, 15180, 15240, 19020, 19140, 26760, 27180, 30360, 30419, 41880, 42600, 49020, 49020, 54840, 55860, 63840, 64020, 69120, 69300, 74040, 75479, 90300, 91440, 100920, 100980, 108300, 108360, 112620].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 28+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_8, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 7200, 7200, 13440, 13500, 16560, 16620, 23040, 23220, 25980, 25980, 35880, 35880, 42300, 42360, 47519, 47760, 55379, 55560, 60599, 60900, 65460, 65700, 80639, 81300, 90600, 90660, 97920, 97980, 102120].cycle)
    effort
  end

  # This factory builds a realistic set of split_times representing a 25+ hour effort on the Hardrock counter-clockwise course.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  factory :split_times_hardrock_9, class: SplitTime do
    sequence(:split_id, [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016].cycle)
    sequence(:bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].cycle)
    sequence(:time_from_start, [0, 7259, 7259, 13080, 13080, 15900, 15900, 21960, 21960, 24720, 24720, 33720, 33840, 38160, 39360, 44400, 44640, 51360, 51420, 55560, 55800, 59340, 59580, 73680, 73980, 81780, 81900, 88740, 88740, 92700].cycle)
    effort
  end
end