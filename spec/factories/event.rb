FactoryBot.define do
  factory :event do
    name { "#{rand(2010..2020)} #{FFaker::Company.name} #{rand(1..10) * 25}" }

    # Samoa causes Capybara to throw ambiguous match errors, so remove it before picking

    home_time_zone { ActiveSupport::TimeZone.all.reject { |timezone| timezone.name == 'Samoa' }.shuffle.first.name }
    start_time { FFaker::Time.datetime }
    laps_required 1
    course
    event_group

    transient { without_slug false }

    after(:build, :stub) do |event, evaluator|
      event.slug = event.name.parameterize unless evaluator.without_slug
    end

    factory :event_with_standard_splits do

      transient { splits_count 4 }
      transient { in_sub_splits_only false }

      after(:stub) do |event, evaluator|
        course = build_stubbed(:course_with_standard_splits, splits_count: evaluator.splits_count,
                               in_sub_splits_only: evaluator.in_sub_splits_only)
        assign_fg_stub_relations(event, {course: course, splits: course.splits})
        assign_fg_stub_relations(course, {events: [event]})
      end

      after(:create) do |event, evaluator|
        course = create(:course_with_standard_splits, splits_count: evaluator.splits_count,
                        in_sub_splits_only: evaluator.in_sub_splits_only)
        course.reload
        event.update(course: course)
        event.splits << course.splits
      end
    end

    factory :event_functional do

      transient do
        splits_count 4
        efforts_count 5
        laps_required 1
        unlimited_laps_generated 3
      end

      after(:stub) do |event, evaluator|
        course = build_stubbed(:course_with_standard_splits, splits_count: evaluator.splits_count)
        splits = course.splits.to_a
        sub_splits = splits.flat_map(&:sub_splits)
        event.laps_required = evaluator.laps_required
        laps_generated = event.laps_required.zero? ? evaluator.unlimited_laps_generated : event.laps_required
        time_points = sub_splits.each_with_iteration.first(sub_splits.size * laps_generated)
                          .map { |sub_split, iter| TimePoint.new(iter, sub_split.split_id, sub_split.bitkey) }
        efforts = build_stubbed_list(:effort, evaluator.efforts_count)

        efforts.each do |effort|
          split_times = build_stubbed_list(:split_times_in_out, 20, effort: effort).first(time_points.size)
          split_times.each_with_index do |split_time, i|
            split_time.time_point = time_points[i]
          end
          assign_fg_stub_relations(effort, {split_times: split_times, event: event})
        end

        all_split_times = efforts.flat_map(&:split_times)
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

# FactoryBot assumes relations are persisted if the resource in question has an id.
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
