FactoryGirl.define do
  factory :course do
    sequence(:name) { |n| "Course #{n}" }

    factory :course_with_splits do

      transient { splits_count 4 }

      after(:stub) do |course, evaluator|
        build_stubbed(:start_split, course: course)
        build_stubbed_list(:split, evaluator.splits_count - 2, course: course)
        build_stubbed(:finish_split, course: course)
      end

      after(:build) do |course, evaluator|
        build(:start_split, course: course)
        build_list(:split, evaluator.splits_count - 2, course: course)
        build(:finish_split, course: course)
      end

      after(:create) do |course, evaluator|
        create(:start_split, course: course)
        create_list(:split, evaluator.splits_count - 2, course: course)
        create(:finish_split, course: course)
      end
    end
  end
end