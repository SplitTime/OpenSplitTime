require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe NewLiveEffortData do
  let(:split_times_4) { FactoryGirl.build_stubbed_list(:split_times_hardrock_36, 30, effort_id: 104) }
  let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe '#initialize' do
    it 'initializes with an event and params in an args hash' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(event: event, params: params) }.not_to raise_error
    end

    it 'raises an ArgumentError if no event is given' do
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(params: params) }.to raise_error(/must include event/)
    end

    it 'raises an ArgumentError if any parameter other than event, params, lap_splits, or times_container is given' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort = Effort.new
      expect { NewLiveEffortData.new(event: event, params: params, lap_splits: [], effort: effort,
                                     times_container: times_container, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#new_split_times' do
    let(:test_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 3, splits_count: 3, efforts_count: 1) }
    let(:test_effort) { test_event.efforts.first }

    context 'for an unstarted effort' do
      it 'returns a hash of {in: SplitTime, out: SplitTime.null_record} when the lap_split contains only an in sub_split' do
        lap_splits, _ = lap_splits_and_time_points(test_event)
        effort = test_effort
        split_times = []
        lap_split = lap_splits[0]
        allow(effort).to receive(:split_times).and_return(split_times)
        params = {'splitId' => split.id.to_s, lap: '1', 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: test_event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times.size).to eq(2)
        expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
        expect(effort_data.new_split_times[:in].null_record?).to eq(false)
        expect(effort_data.new_split_times[:out].null_record?).to eq(true)
      end

      it 'returns a hash of sub_split kinds and SplitTimes when the split contains multiple sub_splits' do
        ordered_splits = splits
        effort = test_effort
        split_times = []
        split = ordered_splits[1]
        allow(effort).to receive(:split_times).and_return(split_times)
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times.size).to eq(2)
        expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
        expect(effort_data.new_split_times[:out]).to be_a(SplitTime)
      end

      it 'populates split_times with correct times from start' do
        ordered_splits = splits
        effort = test_effort
        split_times = []
        split = ordered_splits[1]
        allow(test_effort).to receive(:split_times).and_return(split_times)
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: test_effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].time_from_start).to eq(150.minutes)
        expect(effort_data.new_split_times[:out].time_from_start).to eq(170.minutes)
      end
    end

    context 'when effort is a null_record, as when a bib number is not provided or not located' do
      it 'returns split_times with nil times from start and nil data statuses' do
        ordered_splits = splits
        effort = Effort.null_record
        split_times = []
        split = ordered_splits[1]
        allow(effort).to receive(:split_times).and_return(split_times)
        params = {'splitId' => split.id.to_s, 'bibNumber' => '', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].time_from_start).to be_nil
        expect(effort_data.new_split_times[:out].time_from_start).to be_nil
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to be_nil
      end
    end

    context 'when split_times for the given effort and split do not yet exist in the database' do
      it 'returns a hash of {in: SplitTime, out: SplitTime.null_record} when the split contains only an in sub_split' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[0]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times.size).to eq(2)
        expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
        expect(effort_data.new_split_times[:in].null_record?).to eq(false)
        expect(effort_data.new_split_times[:out].null_record?).to eq(true)
      end

      it 'returns a hash of sub_split kinds and SplitTimes when the split contains multiple sub_splits' do
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
        expect(effort_data.new_split_times.size).to eq(2)
        expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
        expect(effort_data.new_split_times[:out]).to be_a(SplitTime)
      end

      it 'populates split_times with correct times from start when both times are provided' do
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
        expect(effort_data.new_split_times[:in].time_from_start).to eq(150.minutes)
        expect(effort_data.new_split_times[:out].time_from_start).to eq(170.minutes)
      end

      it 'populates split_times with correct times from start when only first time is provided' do
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
        expect(effort_data.new_split_times[:in].time_from_start).to eq(150.minutes)
        expect(effort_data.new_split_times[:out].time_from_start).to be_nil
      end

      it 'populates split_times with correct times from start when only second time is provided' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '08:30:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].time_from_start).to be_nil
        expect(effort_data.new_split_times[:out].time_from_start).to eq(150.minutes)
      end

      it 'populates split_times with nil times_from_start when neither time is provided' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].time_from_start).to be_nil
        expect(effort_data.new_split_times[:out].time_from_start).to be_nil
      end

      it 'populates data_status with correct data statuses when times are both good' do
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
        expect(effort_data.new_split_times[:in].data_status).to eq('good')
        expect(effort_data.new_split_times[:out].data_status).to eq('good')
      end

      it 'populates data_status with correct data statuses when times are both questionable' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '07:15:00', 'timeOut' => '07:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('questionable')
        expect(effort_data.new_split_times[:out].data_status).to eq('questionable')
      end

      it 'populates data_status with correct data statuses when times are both bad' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '06:30:00', 'timeOut' => '06:35:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('bad')
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end

      it 'populates data_status with correct data statuses when first time is good and second time is prior to first' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('good')
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end

      it 'looks past first time to determine data status of second time when first time is bad' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '18:00:00', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('bad')
        expect(effort_data.new_split_times[:out].data_status).to eq('good')
      end

      it 'works properly when first time is missing and second time is good' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to eq('good')
      end

      it 'works properly when first time is missing and second time is bad' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(1)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '07:00:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end
    end

    context 'when split_times for the given effort and split already exist in the database' do
      it 'populates split_times with correct times from start when both times are provided' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1] # Relates to the second and third elements of split_times_4
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].time_from_start).to eq(150.minutes)
        expect(effort_data.new_split_times[:out].time_from_start).to eq(170.minutes)
      end

      it 'populates data_status with correct data statuses when times are both good' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('good')
        expect(effort_data.new_split_times[:out].data_status).to eq('good')
      end

      it 'populates data_status with correct data statuses when times are both bad' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '06:30:00', 'timeOut' => '06:35:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('bad')
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end

      it 'populates data_status with correct data statuses when first time is good and second time is prior to first' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('good')
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end

      it 'looks past first time to determine data status of second time when first time is bad' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '18:00:00', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to eq('bad')
        expect(effort_data.new_split_times[:out].data_status).to eq('good')
      end

      it 'measures the second time against the existing first time in the database when first time is missing' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3) # Existing in and out times are 08:27
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '08:20:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to eq('bad') # Because 08:20 < 08:27 although 2h20m is a reasonable time
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '08:30:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to eq('good') # Because 08:30 > 08:27 and 2h30m is a reasonable time
      end

      it 'works properly when first time is missing and second time is bad on its own merits' do
        ordered_splits = splits
        effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
        split_times = split_times_4.first(3)
        allow(effort).to receive(:split_times).and_return(split_times)
        split = ordered_splits[1]
        params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '06:00:00', 'id' => '4'}
        effort_data = NewLiveEffortData.new(event: event,
                                            params: params,
                                            ordered_splits: ordered_splits,
                                            effort: effort,
                                            times_container: times_container)
        expect(effort_data.new_split_times[:in].data_status).to be_nil
        expect(effort_data.new_split_times[:out].data_status).to eq('bad')
      end
    end

    it 'sets data_status to bad when the effort indicates it has dropped at an earlier split' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed',
                                         gender: 'male', dropped_split_id: ordered_splits[2].id) # Dropped at Maggie
      split_times = split_times_4.first(5)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[3] # Pole Creek (post-drop)
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '11:30:00', 'timeOut' => '11:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.new_split_times[:in].data_status).to eq('bad')
      expect(effort_data.new_split_times[:out].data_status).to eq('bad')
    end
  end

  describe '#times_exist' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20, start_time: '2016-07-01 06:00:00') }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

    it 'returns a hash indicating the presence (true or false) if split_times for the provided split and effort' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(3)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.times_exist[:in]).to eq(true)
      expect(effort_data.times_exist[:out]).to eq(true)
    end

    it 'functions when only the in time exists' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(2)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.times_exist[:in]).to eq(true)
      expect(effort_data.times_exist[:out]).to eq(false)
    end

    it 'functions when only the out time exists' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4[2..3]
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.times_exist[:in]).to eq(false)
      expect(effort_data.times_exist[:out]).to eq(true)
    end

    it 'returns nil for any sub_split kind that is not associated with the provided split' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(5)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[0]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.times_exist[:in]).to eq(true)
      expect(effort_data.times_exist[:out]).to be_nil
    end

    it 'functions the same when times are not provided' do
      ordered_splits = splits
      effort = FactoryGirl.build_stubbed(:effort, id: 104, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      split_times = split_times_4.first(3)
      allow(effort).to receive(:split_times).and_return(split_times)
      split = ordered_splits[1]
      params = {'splitId' => split.id.to_s, 'bibNumber' => '205', 'timeIn' => '', 'timeOut' => '', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      expect(effort_data.times_exist[:in]).to eq(true)
      expect(effort_data.times_exist[:out]).to eq(true)
    end
  end

  def lap_splits_and_time_points(event)
    allow(event).to receive(:ordered_splits).and_return(event.splits)
    lap_splits = event.required_lap_splits
    time_points = lap_splits.map(&:time_points).flatten
    [lap_splits, time_points]
  end
end