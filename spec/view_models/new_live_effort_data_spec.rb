require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe NewLiveEffortData do
  before do
    FactoryGirl.reload
  end
  let(:test_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 3, splits_count: 5, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe '#initialize' do
    it 'initializes with an event and params in an args hash' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'lap' => '1', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(event: event, params: params) }.not_to raise_error
    end

    it 'raises an ArgumentError if no event is given' do
      params = {'splitId' => '2', 'lap' => '1', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(params: params) }.to raise_error(/must include event/)
    end

    it 'raises an ArgumentError if any parameter other than event, params, lap_splits, or times_container is given' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'lap' => '1', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort = Effort.new
      expect { NewLiveEffortData.new(event: event, params: params, ordered_splits: [], effort: effort,
                                     times_container: times_container, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#new_split_times' do
    context 'for an unstarted effort' do
      it 'returns a hash of {in: SplitTime, out: SplitTime.null_record} when the lap_split contains only an in sub_split' do
        event = test_event
        effort = test_effort
        split_times = []
        provided_split = event.splits[0]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {class: SplitTime, :null_record? => false},
                      out: {class: SplitTime, :null_record? => true}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'returns a hash of sub_split kinds and SplitTimes when the split contains multiple sub_splits' do
        event = test_event
        effort = test_effort
        split_times = []
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {class: SplitTime, :null_record? => false},
                      out: {class: SplitTime, :null_record? => false}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates split_times with correct times from start' do
        event = test_event
        effort = test_effort
        split_times = []
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {time_from_start: 150.minutes},
                      out: {time_from_start: 170.minutes}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end
    end

    context 'when effort is a null_record, as when a bib number is not provided or not located' do
      it 'returns split_times with nil times from start and nil data statuses' do
        event = test_event
        effort = Effort.null_record
        split_times = []
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '', 'bibNumber' => '',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {time_from_start: nil, data_status: nil},
                      out: {time_from_start: nil, data_status: nil}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end
    end

    context 'when split_times for the given effort and split do not yet exist in the database' do
      it 'returns a hash of {in: SplitTime, out: SplitTime.null_record} when the split contains only an in sub_split' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[0]
        params = {'splitId' => provided_split.id.to_s, lap: '', 'bibNumber' => '',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {class: SplitTime, :null_record? => false},
                      out: {class: SplitTime, :null_record? => true}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'returns a hash of sub_split kinds and SplitTimes when the split contains multiple sub_splits' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '', 'bibNumber' => '',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {class: SplitTime, :null_record? => false},
                      out: {class: SplitTime, :null_record? => false}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates split_times with correct times from start when both times are provided' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {time_from_start: 150.minutes},
                      out: {time_from_start: 170.minutes}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates split_times with correct times from start when only first time is provided' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '', 'id' => '4'}
        attributes = {in: {time_from_start: 150.minutes},
                      out: {time_from_start: nil}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates split_times with correct times from start when only second time is provided' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {time_from_start: nil},
                      out: {time_from_start: 170.minutes}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates split_times with nil times_from_start when neither time is provided' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '', 'id' => '4'}
        attributes = {in: {time_from_start: nil},
                      out: {time_from_start: nil}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when times are both good' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {data_status: 'good'},
                      out: {data_status: 'good'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when times are both questionable' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '06:35:00', 'timeOut' => '06:40:00', 'id' => '4'}
        attributes = {in: {data_status: 'questionable'},
                      out: {data_status: 'questionable'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when times are both bad' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '06:25:00', 'timeOut' => '06:30:00', 'id' => '4'}
        attributes = {in: {data_status: 'bad'},
                      out: {data_status: 'bad'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when first time is good and second time is prior to first' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:20:00', 'id' => '4'}
        attributes = {in: {data_status: 'good'},
                      out: {data_status: 'bad'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'looks past "in" time to determine data status of "out" time when "in" time is bad' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '18:00:00', 'timeOut' => '08:20:00', 'id' => '4'}
        attributes = {in: {data_status: 'bad'},
                      out: {data_status: 'good'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'works properly when first time is missing and second time is good' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '08:20:00', 'id' => '4'}
        attributes = {in: {data_status: nil},
                      out: {data_status: 'good'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'works properly when first time is missing and second time is bad' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(1)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '06:20:00', 'id' => '4'}
        attributes = {in: {data_status: nil},
                      out: {data_status: 'bad'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end
    end

    context 'when split_times for the given effort and split already exist in the database' do
      it 'populates split_times with correct times from start when both times are provided' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3)
        provided_split = event.splits[1] # Relates to the second and third elements of split_times
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {time_from_start: 150.minutes},
                      out: {time_from_start: 170.minutes}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when times are both good' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3)
        provided_split = event.splits[1] # Relates to the second and third elements of split_times
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
        attributes = {in: {data_status: 'good'},
                      out: {data_status: 'good'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when times are both bad' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3)
        provided_split = event.splits[1] # Relates to the second and third elements of split_times
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '06:20:00', 'timeOut' => '06:25:00', 'id' => '4'}
        attributes = {in: {data_status: 'bad'},
                      out: {data_status: 'bad'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'populates data_status with correct data statuses when first time is good and second time is prior to first' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '08:30:00', 'timeOut' => '08:20:00', 'id' => '4'}
        attributes = {in: {data_status: 'good'},
                      out: {data_status: 'bad'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'looks past "in" time to determine data status of "out" time when "in" time is bad' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3)
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '18:00:00', 'timeOut' => '08:20:00', 'id' => '4'}
        attributes = {in: {data_status: 'bad'},
                      out: {data_status: 'good'}}
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'measures the "out" time against the existing "in" time in the database when "in" time is missing' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3) # Existing in and out times are 07:40 and 07:50
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '07:35:00', 'id' => '4'}
        attributes = {in: {data_status: nil},
                      out: {data_status: 'bad'}} # Because 07:35 < 07:40 although 1h35m is a reasonable time
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'again measures the "out" time against the existing "in" time in the database when "in" time is missing' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3) # Existing in and out times are 07:40 and 07:50
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '07:45:00', 'id' => '4'}
        attributes = {in: {data_status: nil},
                      out: {data_status: 'good'}} # Because 07:45 > 07:40 and 1h45m is a reasonable time
        validate_new_split_times(event, effort, split_times, params, attributes)
      end

      it 'works properly when first time is missing and second time is bad on its own merits' do
        event = test_event
        effort = test_effort
        split_times = effort.split_times.first(3) # Existing in and out times are 07:40 and 07:50
        provided_split = event.splits[1]
        params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                  'timeIn' => '', 'timeOut' => '06:20:00', 'id' => '4'}
        attributes = {in: {data_status: nil},
                      out: {data_status: 'bad'}} # Because 20m is not a reasonable time
        validate_new_split_times(event, effort, split_times, params, attributes)
      end
    end

    it 'sets data_status to bad when the effort indicates it has dropped at an earlier split' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times.first(5)
      provided_split = event.splits.fourth
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '11:30:00', 'timeOut' => '11:50:00', 'id' => '4'}
      attributes = {in: {data_status: 'good'},
                    out: {data_status: 'good'}} # 5h30m and 5h50m are good times for the fourth split
      validate_new_split_times(event, effort, split_times, params, attributes)

      effort.dropped_split_id = event.splits.third.id # But if effort has dropped at the third split
      effort.dropped_lap = 1
      attributes = {in: {data_status: 'bad'},
                    out: {data_status: 'bad'}} # They become bad times
      validate_new_split_times(event, effort, split_times, params, attributes)
    end

    def validate_new_split_times(event, effort, split_times, params, attributes)
      ordered_splits = event.splits
      allow(event).to receive(:ordered_splits).and_return(ordered_splits)
      allow(effort).to receive(:ordered_split_times).and_return(split_times)
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      attributes.each do |in_out, pairs|
        pairs.each do |attribute, expected|
          expect(effort_data.new_split_times[in_out].send(attribute)).to eq(expected)
        end
      end
    end
  end

  describe '#times_exist' do
    it 'returns a hash indicating the presence (true or false) if split_times for the provided split and effort' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times.first(3)
      provided_split = event.splits[1]
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      attributes = {in: true, out: true}
      validate_times_exist(event, effort, split_times, params, attributes)
    end

    it 'functions when only the in time exists' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times.first(2)
      provided_split = event.splits[1]
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      attributes = {in: true, out: false}
      validate_times_exist(event, effort, split_times, params, attributes)
    end

    it 'functions when only the out time exists' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times[2..3]
      provided_split = event.splits[1]
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      attributes = {in: false, out: true}
      validate_times_exist(event, effort, split_times, params, attributes)
    end

    it 'returns nil for a sub_split kind that is not associated with the provided split' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times.first(5)
      provided_split = event.splits[0]
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      attributes = {in: true, out: nil}
      validate_times_exist(event, effort, split_times, params, attributes)
    end

    it 'functions the same when times are not provided' do
      event = test_event
      effort = test_effort
      split_times = effort.split_times.first(3)
      provided_split = event.splits[1]
      params = {'splitId' => provided_split.id.to_s, lap: '1', 'bibNumber' => '205',
                'timeIn' => '', 'timeOut' => '', 'id' => '4'}
      attributes = {in: true, out: true}
      validate_times_exist(event, effort, split_times, params, attributes)
    end

    def validate_times_exist(event, effort, split_times, params, attributes)
      ordered_splits = event.splits
      allow(event).to receive(:ordered_splits).and_return(ordered_splits)
      allow(effort).to receive(:ordered_split_times).and_return(split_times)
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort,
                                          times_container: times_container)
      attributes.each do |in_out, expected|
        expect(effort_data.times_exist[in_out]).to eq(expected)
      end
    end
  end
end