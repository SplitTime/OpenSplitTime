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
end