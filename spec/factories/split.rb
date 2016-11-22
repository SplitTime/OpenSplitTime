FactoryGirl.define do
  factory :split do
    sequence(:base_name) { |n| "Split #{n}" }
    sequence(:distance_from_start, aliases: :finish_split) { |d| d * 10000 }
    sub_split_bitmap 65
    kind :intermediate
    course
  end

  factory :start_split, class: Split do
    base_name 'Start Split'
    distance_from_start 0
    sub_split_bitmap 1
    kind :start
    course
  end

  factory :finish_split, class: Split do
    base_name 'Finish Split'
    sequence(:distance_from_start) { |d| d * 10000 }
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
    course
  end
end