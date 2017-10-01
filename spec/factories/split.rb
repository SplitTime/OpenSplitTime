FactoryGirl.define do
  sequence(:distance_from_start) do |d|
    d * 10000
  end

  sequence(:vert_gain_from_start) do |d|
    d * 100
  end

  sequence(:vert_loss_from_start) do |d|
    d * 100
  end

  factory :split do
    sequence(:base_name) { |n| "Split #{n}" }
    distance_from_start
    vert_gain_from_start
    vert_loss_from_start
    sub_split_bitmap 65
    kind :intermediate
    course

    trait :with_lat_lon do
      latitude { rand(-70..70) }
      longitude { rand(-140..140) }
    end
  end

  factory :start_split, class: Split do
    base_name 'Start Split'
    distance_from_start 0
    vert_gain_from_start 0
    vert_loss_from_start 0
    sub_split_bitmap 1
    kind :start
    course
  end

  factory :finish_split, class: Split do
    base_name 'Finish Split'
    distance_from_start
    vert_gain_from_start
    vert_loss_from_start
    sub_split_bitmap 1
    kind :finish
    course
  end

  # This factory builds a realistic set of splits representing the Hardrock counter-clockwise course.
  # Build all 16 splits at a time to keep sequences in sync. If you need fewer than 16, call .first(n) on the result.

  factory :splits_hardrock_ccw, class: Split do
    sequence(:id, (1001..1016).cycle)
    sequence(:base_name, %w(Start Cunningham Maggie PoleCreek Sherman Burrows Grouse Engineer Ouray Governor Kroger Telluride Chapman KT Putnam Finish).cycle)
    sequence(:sub_split_bitmap, ([1] + [65] * 14 + [1]).cycle)
    sequence(:kind, ([:start] + [:intermediate] * 14 + [:finish]).cycle)
    sequence(:distance_from_start, [0, 14966, 24783, 31704, 46349, 52464, 67914, 78375, 91088, 103802, 109113, 117160, 132127, 143392, 152404, 161739].cycle)
    sequence(:vert_gain_from_start, [0.0, 1170.4, 2133.6, 2426.2, 2849.9, 3084.6, 4452.5, 5156.6, 5295.3, 6254.8, 6961.9, 6974.1, 8345.7, 9235.7, 9974.9, 10073.6].cycle)
    sequence(:vert_loss_from_start, [0.0, 844.3, 1362.5, 1770.9, 2749.3, 2749.3, 4025.8, 4397.7, 5792.1, 5806.7, 5806.7, 7144.8, 8086.6, 8833.4, 9276.9, 10073.6].cycle)
    course
  end
end