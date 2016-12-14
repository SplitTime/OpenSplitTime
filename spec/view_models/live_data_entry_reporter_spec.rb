require 'rails_helper'
# include ActionDispatch::TestProcess

RSpec.describe LiveDataEntryReporter do
  let(:split_times_4) { FactoryGirl.build_stubbed_list(:split_times_hardrock_4, 30, effort_id: 104) }
  let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

  describe '#initialize' do
    it 'initializes with an event and params and a LiveEffortData object in an args hash' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(NewLiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data) }.not_to raise_error
    end

    it 'raises an ArgumentError if no event is given' do
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(NewLiveEffortData)
      expect { LiveDataEntryReporter.new(params: params, effort_data: effort_data) }.to raise_error(/must include event/)
    end

    it 'raises an ArgumentError if no params are given' do
      event = FactoryGirl.build_stubbed(:event)
      effort_data = instance_double(NewLiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, effort_data: effort_data) }.to raise_error(/must include params/)
    end

    it 'raises an ArgumentError if any parameter other than event, params, or effort_data is given' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(NewLiveEffortData)
      expect { LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#response_row[:reportText]' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20, start_time: '2016-07-01 06:00:00') }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
    let(:effort_data) { NewLiveEffortData }

    it 'returns the name and time of the furthest reported split when provided split is prior to furthest reported split' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(9) # Through Sherman out
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[2]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      existing_times = effort_data.ordered_existing_split_times
      prior_valid_split_time = existing_times[2]
      last_reported_split_time = existing_times.last
      last_reported_split = ordered_splits.find { |s| s.id == last_reported_split_time.split_id }
      allow(prior_valid_split_time).to receive(:day_and_time).and_return(event.start_time + 2.5.hours)
      allow(last_reported_split_time).to receive(:day_and_time).and_return(event.start_time + 7.hours)
      allow(last_reported_split_time).to receive(:split).and_return(last_reported_split)
      allow(reporter).to receive(:prior_valid_split_time).and_return(prior_valid_split_time)
      allow(reporter).to receive(:last_reported_split_time).and_return(last_reported_split_time)
      expect(reporter.response_row[:reportText]).to eq('Sherman Out at Fri 13:00')
    end

    it 'returns the name and time of the furthest split other than the provided split when provided split is furthest' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(3) # Through Cunningham out
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[2]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '10:30:00', 'timeOut' => '10:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      existing_times = effort_data.ordered_existing_split_times
      prior_valid_split_time = existing_times[2]
      last_reported_split_time = existing_times.last
      last_reported_split = ordered_splits.find { |s| s.id == last_reported_split_time.split_id }
      allow(prior_valid_split_time).to receive(:day_and_time).and_return(event.start_time + 2.5.hours)
      allow(last_reported_split_time).to receive(:day_and_time).and_return(event.start_time + 2.5.hours)
      allow(last_reported_split_time).to receive(:split).and_return(last_reported_split)
      allow(reporter).to receive(:prior_valid_split_time).and_return(prior_valid_split_time)
      allow(reporter).to receive(:last_reported_split_time).and_return(last_reported_split_time)
      expect(reporter.response_row[:reportText]).to eq('Cunningham Out at Fri 08:30')
    end

    it 'returns "n/a" if effort is not located' do
      ordered_splits = splits
      effort = Effort.null_record
      split_times = []
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      expect(reporter.response_row[:reportText]).to eq('n/a')
    end

    it 'returns "Not yet started" if effort is located but has no split_times' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = []
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      expect(reporter.response_row[:reportText]).to eq('Not yet started')
    end
  end

  describe '#response_row[:timeInAid]' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20, start_time: '2016-07-01 06:00:00') }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }
    let(:effort_data) { NewLiveEffortData }

    it 'returns elapsed time formatted in minutes between provided in and out times' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(1)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      prior_valid_split_time = split_times.first
      allow(prior_valid_split_time).to receive(:day_and_time).and_return(event.start_time)
      allow(reporter).to receive(:prior_valid_split_time).and_return(prior_valid_split_time)
      expect(reporter.response_row[:timeInAid]).to eq('20m')
    end

    it 'returns dashes if either in or out time is not provided' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(1)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      prior_valid_split_time = split_times.first
      allow(prior_valid_split_time).to receive(:day_and_time).and_return(event.start_time)
      allow(reporter).to receive(:prior_valid_split_time).and_return(prior_valid_split_time)
      expect(reporter.response_row[:timeInAid]).to eq('--:--')
    end
  end
end