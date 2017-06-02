require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe LiveDataEntryReporter do
  let(:test_event) { FactoryGirl.build_stubbed(:event, id: 20, start_time: '2016-07-01 06:00:00') }
  let(:test_effort) { FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male') }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
  let(:split_times_4) { FactoryGirl.build_stubbed_list(:split_times_hardrock_36, 30, effort_id: 104) }
  let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

  describe '#initialize' do
    it 'initializes with an event and params and a LiveEffortData object in an args hash' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'split_id' => '2', 'bib_number' => '124', 'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(LiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data) }.not_to raise_error
    end

    it 'raises an ArgumentError if no event is given' do
      params = {'split_id' => '2', 'bib_number' => '124', 'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(LiveEffortData)
      expect { LiveDataEntryReporter.new(params: params, effort_data: effort_data) }.to raise_error(/must include event/)
    end

    it 'raises an ArgumentError if no params are given' do
      event = FactoryGirl.build_stubbed(:event)
      effort_data = instance_double(LiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, effort_data: effort_data) }.to raise_error(/must include params/)
    end

    it 'raises an ArgumentError if any parameter other than event, params, or effort_data is given' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'split_id' => '2', 'bib_number' => '124', 'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(LiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#response_row[:reportText]' do
    it 'returns the name and time of the furthest reported split when provided split is prior to furthest reported split' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(9) # Through Sherman out
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '11:30:00', 'time_out' => '11:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 7.hours
      stopped_index = nil
      stopped_time_offset = nil
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('Sherman Out at Fri 13:00')
    end

    it 'returns the name and time of the furthest split other than the provided split when provided split is furthest' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(3) # Through Cunningham out
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '10:30:00', 'time_out' => '10:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 2.5.hours
      stopped_index = nil
      stopped_time_offset = nil
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('Cunningham Out at Fri 08:30')
    end

    it 'adds a stopped addendum when the effort has a split_time with stopped_here at the last reported lap_split' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(9) # Through Sherman out
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 7.hours
      stopped_index = -1
      stopped_time_offset = 7.hours
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('Sherman Out at Fri 13:00 and stopped there')
    end

    it 'adds an additional stopped notation when the effort has a stopped_here split_time before the last reported split' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(9) # Through Sherman out
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 7.hours
      stopped_index = -3
      stopped_time_offset = 5.hours
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('Sherman Out at Fri 13:00 but reported stopped at PoleCreek as of Fri 11:00')
    end

    it 'returns "n/a" if effort is not located' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = Effort.null_record
      split_times = []
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 7.hours
      stopped_index = -3
      stopped_time_offset = 5.hours
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('n/a')
    end

    it 'returns "Not yet started" if effort is located but has no split_times' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = []
      provided_split = ordered_splits[2]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 2
      prior_valid_time_offset = 2.5.hours
      last_reported_time_offset = 7.hours
      stopped_index = -3
      stopped_time_offset = 5.hours
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:reportText]).to eq('Not yet started')
    end
  end

  describe '#response_row[:timeInAid]' do
    it 'returns elapsed time formatted in minutes between provided in and out times' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(1)
      provided_split = ordered_splits[1]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '08:30:00', 'time_out' => '08:50:00', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 0
      prior_valid_time_offset = 0.hours
      last_reported_time_offset = 0.hours
      stopped_index = nil
      stopped_time_offset = nil
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:timeInAid]).to eq('20m')
    end

    it 'returns dashes if neither in nor out time is provided' do
      event, ordered_splits, lap_splits = resources_for_test_event
      effort = test_effort
      split_times = split_times_4.first(1)
      provided_split = ordered_splits[1]
      params = {'split_id' => provided_split.id.to_s, lap: '1', 'bib_number' => '205',
                'time_in' => '', 'time_out' => '', 'id' => '4'}
      effort_data = build_live_effort_data(event, effort, split_times, ordered_splits, params)

      prior_valid_index = 0
      prior_valid_time_offset = 0.hours
      last_reported_time_offset = 0.hours
      stopped_index = nil
      stopped_time_offset = nil
      reporter = build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                                last_reported_time_offset, stopped_index, stopped_time_offset)
      expect(reporter.full_report[:timeInAid]).to eq('--')
    end
  end

  def resources_for_test_event
    event = test_event
    ordered_splits = splits
    allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
    lap_splits = event.required_lap_splits
    [event, ordered_splits, lap_splits]
  end

  def build_live_effort_data(event, effort, split_times, ordered_splits, params)
    allow(event).to receive(:ordered_splits).and_return(ordered_splits)
    allow(effort).to receive(:ordered_split_times).and_return(split_times)
    LiveEffortData.new(event: event,
                       params: params,
                       ordered_splits: ordered_splits,
                       effort: effort,
                       times_container: times_container)
  end

  def build_reporter(event, params, effort_data, lap_splits, prior_valid_index, prior_valid_time_offset,
                     last_reported_time_offset, stopped_index, stopped_time_offset)
    existing_times = effort_data.ordered_existing_split_times
    prior_valid_split_time = existing_times[prior_valid_index]
    last_reported_split_time = existing_times.last
    last_reported_lap_split = lap_splits.find { |lap_split| lap_split.key == last_reported_split_time.try(:lap_split_key) }
    stopped_split_time = existing_times[stopped_index] if stopped_index
    stopped_split_time.stopped_here = true if stopped_split_time
    allow(effort_data).to receive(:response_row).and_return({})
    reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
    allow(prior_valid_split_time).to receive(:day_and_time).and_return(event.start_time + prior_valid_time_offset) if prior_valid_split_time
    allow(last_reported_split_time).to receive(:day_and_time).and_return(event.start_time + last_reported_time_offset) if last_reported_split_time
    allow(stopped_split_time).to receive(:day_and_time).and_return(event.start_time + stopped_time_offset) if stopped_split_time
    allow(last_reported_split_time).to receive(:split).and_return(last_reported_lap_split.split) if last_reported_split_time
    reporter
  end
end
