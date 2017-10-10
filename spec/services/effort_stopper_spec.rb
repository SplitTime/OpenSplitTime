require 'rails_helper'

RSpec.describe EffortStopper do
  before do
    FactoryGirl.reload
  end

  let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_multi_lap, 18,
                                                     effort: test_effort, stopped_here: false) }
  let(:test_effort) { FactoryGirl.build_stubbed(:effort, event_id: 50) }

  describe '#initialize' do
    it 'initializes with an effort and ordered_split_times in an args hash' do
      effort = test_effort
      ordered_split_times = split_times
      expect { EffortStopper.new(effort: effort, ordered_split_times: ordered_split_times) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no effort is given' do
      ordered_split_times = split_times
      expect { EffortStopper.new(ordered_split_times: ordered_split_times) }
          .to raise_error(/must include effort/)
    end
  end

  describe '#assign_stop' do
    context 'when stopped_split_time has been provided' do
      it 'sets stopped_split_time.stopped_here to true and all other split_times stopped_here to false' do
        effort = test_effort
        ordered_split_times = split_times
        stopped_split_time = split_times.fifth
        validate_stops(effort, ordered_split_times, stopped_split_time)
      end
    end

    context 'when stopped_split_time is not provided' do
      it 'sets final split_time.stopped_here to true and all other split_times stopped_here to false' do
        effort = test_effort
        ordered_split_times = split_times
        validate_stops(effort, ordered_split_times, nil)
      end
    end

    def validate_stops(effort, ordered_split_times, stopped_split_time)
      intended_stop = stopped_split_time || ordered_split_times.last
      stopper = EffortStopper.new(effort: effort, ordered_split_times: ordered_split_times,
                                  stopped_split_time: stopped_split_time)
      stopper.assign_stop
      ordered_split_times.each do |st|
        expect(st.stopped_here).to eq(st == intended_stop)
      end
    end
  end
end
