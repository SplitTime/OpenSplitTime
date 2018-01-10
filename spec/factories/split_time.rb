FactoryBot.define do
  STANDARD_SPLIT_IDS ||= [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111]
  STANDARD_BITKEYS ||= [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1]
  STANDARD_TIMES_FROM_START ||= {normal: [0, 6000, 6600, 12000, 12600, 18000, 18600, 24000, 24600, 30000, 30600, 36000, 36600, 42000, 42600, 48000, 48600, 54000, 54600, 60000],
                                 fast: [0, 4200, 4500, 8400, 8700, 12600, 12900, 16800, 17100, 21000, 21300, 25200, 25500, 29400, 29700, 33600, 33900, 37800, 38100, 42000],
                                 slow: [0, 9000, 9600, 18000, 18600, 27000, 27600, 36000, 36600, 45000, 45600, 54000, 54600, 63000, 63600, 72000, 72600, 81000, 81600, 90000]}

  factory :split_time do
    sequence(:split_id, STANDARD_SPLIT_IDS.cycle)
    sequence(:bitkey, STANDARD_BITKEYS.cycle)
    sequence(:time_from_start, STANDARD_TIMES_FROM_START[:normal].cycle)
    lap 1
    effort
  end

  factory :split_times_in_out, class: SplitTime do
    sequence(:split_id, STANDARD_SPLIT_IDS.cycle)
    sequence(:bitkey, STANDARD_BITKEYS.cycle)
    sequence(:time_from_start, STANDARD_TIMES_FROM_START[:normal].cycle)
    lap 1
    effort
  end

  factory :split_times_in_out_fast, class: SplitTime do
    sequence(:split_id, STANDARD_SPLIT_IDS.cycle)
    sequence(:bitkey, STANDARD_BITKEYS.cycle)
    sequence(:time_from_start, STANDARD_TIMES_FROM_START[:fast].cycle)
    lap 1
    effort
  end

  factory :split_times_in_out_slow, class: SplitTime do
    sequence(:split_id, STANDARD_SPLIT_IDS.cycle)
    sequence(:bitkey, STANDARD_BITKEYS.cycle)
    sequence(:time_from_start, STANDARD_TIMES_FROM_START[:slow].cycle)
    lap 1
    effort
  end

  factory :split_times_in_only, class: SplitTime do
    sequence(:split_id, (201..220).cycle)
    sequence(:bitkey, SubSplit::IN_BITKEY)
    sequence(:time_from_start, (0..19).cycle) { |n| n * 1000 }
    lap 1
    effort
  end

  # The split_times_multi_lap factory builds a split times for up to three laps of a multi-lap course.
  # Build 18 split_times at once to keep sequences in sync. If you need fewer than 18, call .first(n) on the result.

  MULTI_LAP_SPLIT_IDS ||= [101, 102, 102, 103, 103, 104]
  MULTI_LAP_BITKEYS ||= [1, 1, 64, 1, 64, 1]
  MULTI_LAP_LAPS ||= [1] * 6 + [2] * 6 + [3] * 6
  MULTI_LAP_TIMES_FROM_START ||= {normal: [0, 1000, 1100, 2000, 2100, 3000, 3100, 4000, 4100, 5000, 5100, 6000, 6100, 7000, 7100, 8000, 8100, 9000],
                                  fast: [0, 700, 750, 1400, 1450, 2100, 2150, 2800, 2850, 3500, 3550, 4200, 4250, 4900, 4950, 5600, 5650, 6300],
                                  slow: [0, 1500, 1600, 3000, 3100, 4500, 4600, 6000, 6100, 7500, 7600, 9000, 9100, 10500, 10600, 12000, 12100, 13500]}

  factory :split_times_multi_lap, class: SplitTime do
    sequence(:split_id, MULTI_LAP_SPLIT_IDS.cycle)
    sequence(:bitkey, MULTI_LAP_BITKEYS.cycle)
    sequence(:lap, MULTI_LAP_LAPS.cycle)
    sequence(:time_from_start, MULTI_LAP_TIMES_FROM_START[:normal].cycle)
    effort
  end

  # These factories build realistic sets of split_times representing a efforts on the Hardrock counter-clockwise course.
  # The finish time_from_start is roughly equal to the number at the end of the factory name.
  # For example, split_times_hardrock_41 builds a set of split_times for a 41-hour finish time.
  # Build all 30 split_times at once to keep sequences in sync. If you need fewer than 30, call .first(n) on the result.

  HARDROCK_SPLIT_IDS ||= [1001, 1002, 1002, 1003, 1003, 1004, 1004, 1005, 1005, 1006, 1006, 1007, 1007, 1008, 1008, 1009, 1009, 1010, 1010, 1011, 1011, 1012, 1012, 1013, 1013, 1014, 1014, 1015, 1015, 1016]
  HARDROCK_BITKEYS ||= [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1]
  HARDROCK_TIMES_FROM_START ||= {hours_45: [0, 9960, 9960, 20340, 20580, 25500, 25560, 35100, 36540, 40500, 40620, 57839, 58860, 67980, 68280, 78480, 80100, 90480, 91200, 97860, 98160, 104880, 106140, 125460, 125700, 140640, 141360, 154440, 154800, 163200],
                                 hours_43: [0, 11160, 11160, 20880, 21060, 25680, 25740, 35820, 36480, 40740, 40860, 59340, 60480, 69720, 69900, 79320, 80220, 86400, 88200, 98760, 99240, 104100, 104820, 122400, 125400, 140220, 141000, 155040, 155160, 163860],
                                 hours_41: [0, 9780, 9780, 18720, 18840, 23400, 23460, 33060, 33600, 37860, 38220, 52500, 52620, 61800, 62220, 70920, 71880, 81420, 81600, 87420, 87780, 93120, 94740, 112200, 113160, 127560, 127980, 140400, 140400, 148500],
                                 hours_38: [0, 9180, 9180, 17280, 17579, 21540, 21660, 30000, 31080, 34320, 34440, 48240, 49800, 57960, 58319, 65700, 68340, 78540, 79260, 85380, 85500, 90480, 91980, 108660, 109920, 121980, 122580, 132480, 132780, 139260],
                                 hours_36: [0, 8820, 8820, 15960, 16080, 19560, 19620, 27060, 27960, 30900, 30900, 42720, 43500, 51300, 51300, 63000, 63060, 71220, 71400, 76740, 77100, 82800, 84000, 100380, 101940, 113340, 114000, 124200, 124200, 130860],
                                 hours_35: [0, 8520, 8520, 15660, 15720, 19320, 19380, 27300, 27600, 31380, 31800, 44400, 45180, 53520, 54300, 62580, 63600, 73440, 74820, 80940, 81180, 86520, 87540, 100680, 100680, 111180, 111540, 121560, 121560, 127080],
                                 hours_33: [0, 8460, 8460, 16380, 16440, 20460, 20520, 28560, 28860, 32580, 32580, 43980, 44220, 51300, 51300, 58500, 58560, 66899, 67020, 71760, 72060, 76680, 77160, 93360, 94020, 104940, 105420, 115080, 115080, 120720],
                                 hours_31: [0, 7980, 7980, 15180, 15240, 19020, 19140, 26760, 27180, 30360, 30419, 41880, 42600, 49020, 49020, 54840, 55860, 63840, 64020, 69120, 69300, 74040, 75479, 90300, 91440, 100920, 100980, 108300, 108360, 112620],
                                 hours_28: [0, 7200, 7200, 13440, 13500, 16560, 16620, 23040, 23220, 25980, 25980, 35880, 35880, 42300, 42360, 47519, 47760, 55379, 55560, 60599, 60900, 65460, 65700, 80639, 81300, 90600, 90660, 97920, 97980, 102120],
                                 hours_25: [0, 7259, 7259, 13080, 13080, 15900, 15900, 21960, 21960, 24720, 24720, 33720, 33840, 38160, 39360, 44400, 44640, 51360, 51420, 55560, 55800, 59340, 59580, 73680, 73980, 81780, 81900, 88740, 88740, 92700], }

  factory :split_times_hardrock_45, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_45].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_43, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_43].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_41, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_41].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_38, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_38].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_36, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_36].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_35, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_35].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_33, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_33].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_31, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_31].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_28, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_28].cycle)
    lap 1
    effort
  end

  factory :split_times_hardrock_25, class: SplitTime do
    sequence(:split_id, HARDROCK_SPLIT_IDS.cycle)
    sequence(:bitkey, HARDROCK_BITKEYS.cycle)
    sequence(:time_from_start, HARDROCK_TIMES_FROM_START[:hours_25].cycle)
    lap 1
    effort
  end
end