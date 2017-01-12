require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortDroppedAttributesSetter do
  describe '#initialize' do
    it 'initializes with an effort and an event in an args hash' do
      effort = FactoryGirl.build_stubbed(:effort)
      event = FactoryGirl.build_stubbed(:event)
      ordered_split_times = []
      expect { EffortDroppedAttributesSetter.new(effort: effort,
                                                 event: event,
                                                 ordered_split_times: ordered_split_times) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no effort is given' do
      event = FactoryGirl.build_stubbed(:event)
      expect { EffortDroppedAttributesSetter.new(event: event) }
          .to raise_error(/must include effort/)
    end

    it 'raises an ArgumentError if a param other than effort, event, or ordered_split_times is given' do
      effort = FactoryGirl.build_stubbed(:effort)
      event = FactoryGirl.build_stubbed(:event)
      random_param = 123
      expect { EffortDroppedAttributesSetter.new(effort: effort,
                                                 event: event,
                                                 random_param: random_param) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#set_dropped_attributes' do
    before do
      FactoryGirl.reload
    end

    context 'for an unlimited-lap event' do
      let(:event) { FactoryGirl.build_stubbed(:event, laps_required: 0) }
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_multi_lap, 18) }

      it 'sets dropped attributes to nil if the effort has not started' do
        ordered_split_times = []
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped attributes to nil if the effort has started' do
        ordered_split_times = split_times.first(1)
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end
    end

    context 'for a single-lap event' do
      let(:event) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 1, splits_count: 4) }
      let(:splits) { event.splits }
      let(:sub_splits) { splits.map(&:sub_splits).flatten }
      let(:time_points_count) { sub_splits.size * event.laps_required}
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_in_out, time_points_count) }

      it 'sets dropped attributes to nil if the effort has not started' do
        ordered_split_times = []
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped attributes to nil if the effort has finished' do
        ordered_split_times = split_times
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped_attributes if the effort is unfinished and dropped_attributes exist' do
        ordered_split_times = split_times.first(2)
        existing_split_id = 101
        existing_lap = 2
        expected_split_id = 102
        expected_lap = 1
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped_attributes if the effort is unfinished and dropped_attributes do not exist' do
        ordered_split_times = split_times.first(2)
        existing_split_id = nil
        existing_lap = nil
        expected_split_id = 102
        expected_lap = 1
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end
    end

    context 'for a fixed-multi-lap event' do
      let(:event) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 3, splits_count: 4) }
      let(:splits) { event.splits }
      let(:sub_splits) { splits.map(&:sub_splits).flatten }
      let(:time_points_count) { sub_splits.size * event.laps_required}
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_multi_lap, time_points_count) }

      it 'sets dropped attributes to nil if the effort has not started' do
        ordered_split_times = []
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped attributes to nil if the effort has finished' do
        ordered_split_times = split_times
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = nil
        expected_lap = nil
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped_attributes to the last completed split and lap when dropped_attributes exist' do
        ordered_split_times = split_times.first(8)
        existing_split_id = 101
        existing_lap = 1
        expected_split_id = 102
        expected_lap = 2
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end

      it 'sets dropped_attributes to the last completed split and lap when dropped_attributes do not exist' do
        ordered_split_times = split_times.first(8)
        existing_split_id = nil
        existing_lap = nil
        expected_split_id = 102
        expected_lap = 2
        validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      end
    end

    def validate_dropped_attributes(ordered_split_times, existing_split_id, existing_lap, expected_split_id, expected_lap)
      ordered_splits = event.splits
      test_event = event
      allow(test_event).to receive(:ordered_splits).and_return(ordered_splits)
      effort = Effort.new(dropped_split_id: existing_split_id, dropped_lap: existing_lap)
      allow(effort).to receive(:ordered_split_times).and_return(ordered_split_times)
      allow(effort).to receive(:event).and_return(event)
      EffortDroppedAttributesSetter.new(effort: effort, event: test_event).set_attributes
      expect(effort.dropped_split_id).to eq(expected_split_id)
      expect(effort.dropped_lap).to eq(expected_lap)
    end
  end
end