FactoryBot.define do
  factory :course do
    name { FFaker::Product.product }

    trait :with_description do
      description { FFaker::HipsterIpsum.phrase }
    end

    factory :course_with_standard_splits do

      transient { splits_count 4 }
      transient { in_sub_splits_only false }

      splits do
        intermediate_split_bitmap = in_sub_splits_only ? 1 : 65
        start_split = build_stubbed(:split, :start)
        intermediate_splits = build_stubbed_list(:split, splits_count - 2, sub_split_bitmap: intermediate_split_bitmap)
        finish_split = build_stubbed(:split, :finish)
        [start_split] + intermediate_splits + [finish_split]
      end

      after(:build) do |course, evaluator|
        build(:split, :start, course: course)
        build_list(:split, evaluator.splits_count - 2, course: course)
        build(:split, :finish, course: course)
      end

      after(:create) do |course, evaluator|
        create(:split, :start, course: course)
        create_list(:split, evaluator.splits_count - 2, course: course)
        create(:split, :finish, course: course)
      end
    end
  end
end
