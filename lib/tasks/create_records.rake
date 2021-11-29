# frozen_string_literal: true

require 'action_view/helpers/text_helper'
include ActionView::Helpers::TextHelper

namespace :create_records do
  desc 'Create random efforts for testing'
  task :efforts, [:event_group_id, :effort_count] => :environment do |_, args|
    process_start_time = Time.current
    abort "No event_group_id specified" unless args.event_group_id

    event_group_id = args.event_group_id
    effort_count = args.effort_count.to_i

    saved_efforts_count = 0
    event_group = EventGroup.friendly.find(event_group_id)
    abort "Event group #{event_group_id} not found" unless event_group

    puts "Building test data:"
    events = event_group.events.order(:scheduled_start_time)
    puts "Found #{pluralize(events.size, 'event')}: #{events.map(&:name).to_sentence}"

    events.each_with_index do |event, i|
      bib_number = (i * 100) + 1
      effort_count.times do
        gender = %w(male female).sample
        first_name = FFaker::Name.send("first_name_#{gender}")
        last_name = FFaker::Name.last_name
        birthdate = FFaker::Time.between(16.years.ago, 75.years.ago).to_date
        country_code = 'US'
        state_code = Carmen::Country.coded('US').subregions.map(&:code).sample
        city = FFaker::Address.city
        emergency_contact = FFaker::Name.name
        emergency_phone = FFaker::PhoneNumber.short_phone_number
        user_id = 1

        effort = event.efforts.new(bib_number: bib_number, first_name: first_name, last_name: last_name, gender: gender,
                                   birthdate: birthdate, country_code: country_code, state_code: state_code, city: city,
                                   scheduled_start_time: event.scheduled_start_time, emergency_phone: emergency_phone,
                                   emergency_contact: emergency_contact, created_by: user_id)

        effort_description = "#{effort.full_name} using bib number #{bib_number} for #{event.name}"

        if effort.save
          saved_efforts_count += 1
          puts "Saved #{effort_description}"
        else
          puts "Could not save #{effort_description}:"
          puts effort.errors.full_messages.join("\n")
        end

        bib_number += 1
      end
    end

    elapsed_time = Time.current - process_start_time
    puts "\nCreated #{saved_efforts_count} efforts in #{elapsed_time} seconds"
  end

  desc 'Create ResultsTemplates from yml files'
  task results_templates: :environment do
    process_start_time = Time.current

    ENV['FIXTURES_PATH'] = 'spec/fixtures'
    ENV['FIXTURES'] = 'results_categories,results_templates,results_template_categories'
    Rake::Task['db:fixtures:load'].invoke

    elapsed_time = Time.current - process_start_time
    puts "\nFinished in #{elapsed_time} seconds"
  end

  desc 'Create random raw_time records for testing'
  task :raw_times, [:event_group_id, :effort_count, :laps] => :environment do |_, args|
    process_start_time = Time.current
    abort "No event_group_id specified" unless args.event_group_id

    saved_raw_times_count = 0
    event_group_id = args.event_group_id
    event_group = EventGroup.friendly.find(event_group_id)
    abort "Event group #{event_group_id} not found" unless event_group
    effort_count = args.effort_count.present? ? args.effort_count.to_i : nil
    laps = args.laps.present? ? args.laps.to_i : 1

    puts "Building test data:"
    events = event_group.events
    indexed_events = events.index_by(&:id)
    puts "Found #{pluralize(events.size, 'event')}: #{events.map(&:name).to_sentence}"

    grouped_time_points = events.map do |event|
      [event.id, event.required_time_points.presence || event.time_points_through(laps)]
    end.to_h
    all_time_points = grouped_time_points.values.flatten
    puts "Built #{all_time_points.size} time points"

    grouped_segments = grouped_time_points.transform_values { |time_points| SegmentsBuilder.segments(time_points: time_points) }
    all_segments = grouped_segments.values.flatten.uniq
    stats_container = SegmentTimesContainer.new(calc_model: :stats)
    stats_complete = all_segments.map { |segment| stats_container.segment_time(segment) }.all?
    terrain_container = SegmentTimesContainer.new(calc_model: :terrain)
    times_container = stats_complete ? stats_container : terrain_container
    puts "Computed expected segment times"

    splits = events.flat_map(&:splits).uniq
    indexed_split_names = splits.map { |split| [split.id, split.base_name] }.to_h
    all_split_names = indexed_split_names.values
    puts "Found #{pluralize(all_split_names.size, 'split name')}: #{all_split_names.to_sentence}"

    grouped_bib_numbers = events.map { |event| [event.id, event.efforts.map { |effort| effort.bib_number.to_s }] }.to_h
    all_bib_numbers = grouped_bib_numbers.values.flatten
    puts "Found #{pluralize(all_bib_numbers.size, 'bib number')}"

    puts "Creating random raw_time records for #{pluralize(effort_count, 'effort')}"

    built_raw_times = []
    effort_count ||= (all_bib_numbers.size * 0.9).to_i
    sampled_bib_numbers = all_bib_numbers.sample(effort_count)
    source = 'Rake Task'
    user_id = 1

    sampled_bib_numbers.each do |bib_number|
      event_id = grouped_bib_numbers.find { |_, bib_numbers| bib_numbers.include?(bib_number) }.first
      event = indexed_events[event_id]
      event_start_time = event.scheduled_start_time_local
      laps_required = event.laps_required
      speed_factor = rand(0.75..1.5)

      laps_completed = laps_required == 0 ? 1 + rand(laps - 1) : laps_required
      time_points = event.time_points_through(laps_completed)
      stopped = rand(10) > 7
      completed_count = rand(time_points.size - 1)
      completed_time_points = stopped ? time_points.first(completed_count) : time_points
      completed_segments = SegmentsBuilder.segments(time_points: completed_time_points, splits: splits)
      prior_time_from_start = 0

      completed_segments.each.with_index(1) do |segment, i|
        bib_entry_error = rand(100) > 97
        incorrect_bib_number = rand(10) > 8 ? bib_number.first + '*' : rand(9).to_s + bib_number[1..-1]
        entered_bib_number = bib_entry_error ? incorrect_bib_number : bib_number

        time_point = segment.end_point
        lap = time_point.lap
        split_name = indexed_split_names[time_point.split_id]
        sub_split_kind = SubSplit.kind(time_point.bitkey)

        segment_time = times_container.segment_time(segment) * speed_factor * rand(0.9..1.1)
        time_from_start = prior_time_from_start + segment_time
        absolute_time = event_start_time + time_from_start

        final_segment = (i == completed_segments.size)
        stopped_here = stopped && final_segment

        raw_time = RawTime.new(event_group: event_group,
                               source: source,
                               bib_number: entered_bib_number,
                               lap: lap,
                               split_name: split_name,
                               sub_split_kind: sub_split_kind,
                               absolute_time: absolute_time,
                               stopped_here: stopped_here,
                               created_by: user_id)

        prior_time_from_start = time_from_start
        raw_time_description = "bib: #{raw_time.bib_number}, lap: #{raw_time.lap}, split: #{raw_time.split_name} (#{raw_time.sub_split_kind}) at #{raw_time.absolute_time}"
        missed = rand(100) > 97

        if missed
          puts "Simulated missed " + raw_time_description
        else
          built_raw_times << raw_time
          puts "Built raw time for " + raw_time_description
        end
      end
    end

    sorted_raw_times = built_raw_times.sort_by(&:absolute_time)

    # Mix up some of the raw times to simulate uneven entry order in real-time conditions

    raw_times_count = sorted_raw_times.size
    randomizer_count = raw_times_count / 20
    randomizers = Array.new(randomizer_count).map { [rand(raw_times_count - 1), rand(raw_times_count - 1)] }
    randomizers.each { |a, b| sorted_raw_times[a], sorted_raw_times[b] = sorted_raw_times[b], sorted_raw_times[a] }

    puts "Saving #{pluralize(raw_times_count, 'raw time')}"

    sorted_raw_times.each do |raw_time|
      if raw_time.save
        raw_time_description = "bib: #{raw_time.bib_number}, lap: #{raw_time.lap}, split: #{raw_time.split_name} (#{raw_time.sub_split_kind}) at #{raw_time.absolute_time}"
        puts "Saved raw time for " + raw_time_description
        saved_raw_times_count += 1
      else
        puts "Could not save #{raw_time}"
        puts raw_time.errors.full_messages
        puts raw_time.attributes
      end
    end

    elapsed_time = Time.current - process_start_time
    puts "\nCreated #{saved_raw_times_count} raw times records in #{elapsed_time} seconds"
  end
end
