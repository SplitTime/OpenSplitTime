require 'rails_helper'
# include ActionDispatch::TestProcess

RSpec.describe LiveDataEntryReporter do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

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

  describe '#effort_name' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20) }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

    it 'returns the full name of the effort when an effort is located' do
      effort = FactoryGirl.build_stubbed(:effort, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      params = {'splitId' => split_ids[3], 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(NewLiveEffortData, effort: effort)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      expect(reporter.effort_name).to eq('Johnny Appleseed')
    end

    it 'returns "Bib number not located" if a bib number is provided but not located' do
      params = {'splitId' => split_ids[3], 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = instance_double(NewLiveEffortData, effort: Effort.null_record)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      expect(reporter.effort_name).to eq('Bib number not located')
    end
  end

  describe '#response_row' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20) }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

    it 'returns a hash of response values related to aid station times reported in the form of args[:params]' do
      params = {'splitId' => split_ids[3], 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect(event).to receive(:efforts).and_return(efforts_relation)
      expect(efforts_relation).to receive(:find_by_bib_number).with('205').and_return(effort)
      effort_data = instance_double(NewLiveEffortData)
      reporter = LiveDataEntryReporter.new(event: event, params: params, effort_data: effort_data)
      expect(reporter.response_row).to eq({:splitId => '2',
                                              :bibNumber => '205',
                                              :timeIn => '08:30:00',
                                              :timeOut => '08:50:00',
                                              :pacerIn => false,
                                              :pacerOut => false,
                                              :droppedHere => false,
                                              :effortName => 'Michael Evans',
                                              :splitName => 'Cunningham',
                                              :splitDistance => 14966,
                                              :timeInExists => true,
                                              :timeOutExists => true,
                                              :timeInStatus => 'good',
                                              :timeOutStatus => 'good'})
    end
  end
end