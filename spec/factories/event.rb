FactoryGirl.define do

  factory :event do
    sequence(:name) { |n| "Test Event #{n}" }
    start_time '2016-07-01 06:00:00'
    laps_required 1
    sequence(:staging_id) { SecureRandom.uuid }
    course

    factory :event_with_standard_splits do

      transient { splits_count 4 }

      after(:stub) do |event, evaluator|
        course = build_stubbed(:course_with_standard_splits, splits_count: evaluator.splits_count)
        assign_fg_stub_relations(event, {course: course, splits: course.splits})
        assign_fg_stub_relations(course, {events: [event]})
      end
    end

    factory :event_functional do

      transient do
        splits_count 4
        efforts_count 5
        laps_required 1
        unlimited_laps_generated 3
        start_time '2016-07-01 06:00:00'
      end

      after(:stub) do |event, evaluator|
        course = build_stubbed(:course_with_standard_splits, splits_count: evaluator.splits_count)
        splits = course.splits.to_a
        sub_splits = splits.map(&:sub_splits).flatten
        event.laps_required = evaluator.laps_required
        event.start_time = evaluator.start_time
        laps_generated = event.laps_required.zero? ? evaluator.unlimited_laps_generated : event.laps_required
        time_points = sub_splits.each_with_iteration.first(sub_splits.size * laps_generated)
                          .map { |sub_split, iter| TimePoint.new(iter, sub_split.split_id, sub_split.bitkey) }
        efforts = build_stubbed_list(:effort, evaluator.efforts_count)

        efforts.each do |effort|
          split_times = FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort: effort).first(time_points.size)
          split_times.each_with_index do |split_time, i|
            split_time.time_point = time_points[i]
          end
          assign_fg_stub_relations(effort, {split_times: split_times, event: event})
        end

        all_split_times = efforts.map(&:split_times).flatten
        indexed_split_times = all_split_times.group_by(&:split_id)
        splits.each do |split|
          split_times = indexed_split_times[split.id]
          assign_fg_stub_relations(split, split_times: split_times)
        end
        assign_fg_stub_relations(event, {course: course, splits: splits, efforts: efforts})
        assign_fg_stub_relations(course, {events: [event]})
      end
    end
  end
end

# FactoryGirl assumes relations are persisted if the resource in question has an id.
# To build relations without persisting anything, the resource.id must be removed,
# then the relationship created, then (optionally) the resource.id may be restored.
# See http://stackoverflow.com/a/23283955/5961578
# The method below allows this clunky process to work in a single line of code.
# There seems to be no way to call a method from inside a factory namespace
# except to put the method on Main.

def assign_fg_stub_relations(resource, relations)
  temp_id, resource.id = resource.id, nil
  resource.assign_attributes(relations)
  resource.id = temp_id
end