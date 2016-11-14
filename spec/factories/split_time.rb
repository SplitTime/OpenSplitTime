FactoryGirl.define do
  factory :split_times_in_out, class: SplitTime do
    sequence(:split_id, [101, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106, 107, 107, 108, 108, 109, 109, 110, 110, 111].to_enum)
    sequence(:sub_split_bitkey, [1, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1].to_enum)
    sequence(:time_from_start, [0, 1000, 1100, 2000, 2100, 3000, 3100, 4000, 4100, 5000, 5100, 6000, 6100, 7000, 7100, 8000, 8100, 9000, 9100, 10000].to_enum)
    effort
  end

  factory :split_times_in_only, class: SplitTime do
    sequence(:split_id, (201..220).to_enum)
    sequence(:sub_split_bitkey, SubSplit::IN_BITKEY)
    sequence(:time_from_start, 0) { |n| n * 1000 }
    effort
  end
end