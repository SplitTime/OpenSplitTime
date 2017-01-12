FactoryGirl.define do
  factory :event do
    sequence(:name) { |n| "Test Event #{n}" }
    start_time '2016-07-01 06:00:00'
    laps_required 1
    course

    factory :event_with_standard_splits do

      transient { splits_count 4 }

      after(:stub) do |event, evaluator|
        event.id = nil
        course = build_stubbed(:course_with_standard_splits, splits_count: evaluator.splits_count)
        event.course = course
        event.splits = course.splits
      end
    end
  end
end