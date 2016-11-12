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
end