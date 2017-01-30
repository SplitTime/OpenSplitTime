require 'rails_helper'

RSpec.describe EffortSplitTimeCreator, type: :model do
  let(:excel_epoch) { '1899-12-30'.to_datetime }
  let(:current_user_id) { 1 }
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }
  let(:event_with_one_lap) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 1) }
  let(:event_with_multiple_laps) { FactoryGirl.build_stubbed(:event_with_standard_splits, splits_count: 3, laps_required: 3) }
  let(:event_with_unlimited_laps) { FactoryGirl.build_stubbed(:event_with_standard_splits, splits_count: 3, laps_required: 0) }

  describe '#initialize (validate_row_time_data)' do
    it 'for a single-lap event, does not raise an ArgumentError if row_time_data and event time_points count match' do
      row_time_data = [0, 1000, nil, 3000, nil, 5000]
      error_expected = false
      event = event_with_one_lap
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for a single-lap event, raises an ArgumentError if row_time_data and event time_points count do not match' do
      row_time_data = [0, 1000, nil, 3000]
      error_expected = true
      event = event_with_one_lap
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for a multi-required-lap event, does not raise an ArgumentError if row_time_data and event time_points count match' do
      row_time_data = (0..11).map { |n| n * 1000 }.to_a
      error_expected = false
      event = event_with_multiple_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for a single-lap event, raises an ArgumentError if row_time_data and event time_points count do not match' do
      row_time_data = (0..10).map { |n| n * 1000 }.to_a
      error_expected = true
      event = event_with_multiple_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for an unlimited-lap event, does not raise an ArgumentError if one data point is provided' do
      row_time_data = [0]
      error_expected = false
      event = event_with_unlimited_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for an unlimited-lap event, does not raise an ArgumentError if a partial lap of data points is provided' do
      row_time_data = (0..2).map { |n| n * 1000 }.to_a
      error_expected = false
      event = event_with_unlimited_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for an unlimited-lap event, does not raise an ArgumentError if one lap of data points is provided' do
      row_time_data = (0..3).map { |n| n * 1000 }.to_a
      error_expected = false
      event = event_with_unlimited_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    it 'for an unlimited-lap event, does not raise an ArgumentError if many laps of data points are provided' do
      row_time_data = (0..20).map { |n| n * 1000 }.to_a
      error_expected = false
      event = event_with_unlimited_laps
      validate_row_time_validation(row_time_data, error_expected, event)
    end

    def validate_row_time_validation(row_time_data, error_expected, event)
      allow(event).to receive(:ordered_splits).and_return(event.splits)
      effort = FactoryGirl.build_stubbed(:effort, id: 1001, event: event)
      if error_expected
        expect { EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                            current_user_id: current_user_id, event: event) }
            .to raise_error(ArgumentError)
      else
        expect { EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                            current_user_id: current_user_id, event: event) }
            .not_to raise_error
      end
    end
  end

  describe 'split_times' do
    context 'for a single-lap event' do
      let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 1) }
      let(:effort) { double(:effort, id: 1001, event: event, full_name: 'John Appleseed') }

      it 'returns an array of SplitTime objects the same number as is contained in row_time_data' do
        row_time_data = [0, 1000, nil, 3000, nil, 5000]
        attribute = :class
        expected = [SplitTime] * 4
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets effort_ids uniformly to the id of the effort parameter' do
        row_time_data = [0, 1000, 2000, 3000, 4000, 5000]
        attribute = :effort_id
        expected = [1001] * 6
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets laps properly based on existing times provided' do
        row_time_data = [0, nil, nil, 3000, nil, 5000]
        attribute = :lap
        expected = [1, 1, 1]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets split_ids properly based on existing times provided' do
        row_time_data = [0, nil, nil, 3000, nil, 5000]
        attribute = :split_id
        expected = [101, 103, 104]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets bitkeys properly based on existing times provided' do
        row_time_data = [0, nil, 2000, 3000, nil, 5000]
        attribute = :bitkey
        expected = [in_bitkey, out_bitkey, in_bitkey, in_bitkey]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets time_from_start properly based on existing time data provided' do
        row_time_data = [0, 1000, nil, 3000, nil, 5000]
        attribute = :time_from_start
        expected = [0, 1000, 3000, 5000]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets the start time to zero after setting start_offset' do
        row_time_data = [500, 1000, 2000, 3000, 4000, 5000]
        attribute = :time_from_start
        expected = [0, 1000, 2000, 3000, 4000, 5000]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands time data provided as integer seconds elapsed' do
        row_time_data = [0, 1000, 2000, 3000, 4000, 5000]
        attribute = :time_from_start
        expected = [0, 1000, 2000, 3000, 4000, 5000]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands time data provided as float seconds elapsed' do
        row_time_data = [0.0, 1000.0, 2000.0, 3000.0, 4000.0, 5000.0]
        attribute = :time_from_start
        expected = [0, 1000, 2000, 3000, 4000, 5000]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands time data provided as Excel date values' do
        row_time_data = [excel_epoch, excel_epoch + 1.hour, excel_epoch + 2.hours,
                         excel_epoch + 3.hours, excel_epoch + 4.hours, excel_epoch + 5.hours]
        attribute = :time_from_start
        expected = [0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands elapsed time string data formatted as h:mm:ss' do
        row_time_data = %w(0:00:00 1:00:00 2:00:00 3:00:00 4:00:00 5:00:00)
        attribute = :time_from_start
        expected = [0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands elapsed time string data formatted as h:mm' do
        row_time_data = %w(0:00 1:00 2:00 3:00 4:00 5:00)
        attribute = :time_from_start
        expected = [0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands elapsed time string data with values greater than 24 hours' do
        row_time_data = %w(0:00 10:00 20:00 30:00 40:00 50:00)
        attribute = :time_from_start
        expected = [0, 10.hours, 20.hours, 30.hours, 40.hours, 50.hours]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'understands elapsed time string data with values greater than 100 hours' do
        row_time_data = %w(0:00 100:00 200:00 300:00 400:00 500:00)
        attribute = :time_from_start
        expected = [0, 100.hours, 200.hours, 300.hours, 400.hours, 500.hours]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end
    end

    context 'for a multi-required-lap event' do
      let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, splits_count: 3, laps_required: 3) }
      let(:effort) { double(:effort, id: 1001, event: event, full_name: 'John Appleseed') }
      let(:time_data_with_nils) { [0, 1000, nil, 3000, nil, 5000, 5100, nil, 6000, 7000, 7100, 9000] }

      it 'returns an array of SplitTime objects the same number as is contained in row_time_data' do
        row_time_data = time_data_with_nils
        attribute = :class
        expected = [SplitTime] * 9
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets laps properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :lap
        expected = [1] * 3 + [2] * 2 + [3] * 4
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets split_ids properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :split_id
        expected = [101, 102, 103, 102, 102, 101, 102, 102, 103]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets bitkeys properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :bitkey
        expected = [in_bitkey, in_bitkey, in_bitkey, in_bitkey, out_bitkey, in_bitkey, in_bitkey, out_bitkey, in_bitkey]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end
    end

    context 'for an unlimited-lap event' do
      let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, splits_count: 3, laps_required: 0) }
      let(:effort) { double(:effort, id: 1001, event: event, full_name: 'John Appleseed') }
      let(:time_data_with_nils) { [0, 1000, nil, 3000, 3500, 5000, 5100, 7000, nil, 9000] }

      it 'returns an array of SplitTime objects the same number as is contained in row_time_data' do
        row_time_data = time_data_with_nils
        attribute = :class
        expected = [SplitTime] * 8
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets laps properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :lap
        expected = [1] * 3 + [2] * 4 + [3] * 1
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets split_ids properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :split_id
        expected = [101, 102, 103, 101, 102, 102, 103, 102]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end

      it 'sets bitkeys properly based on existing times provided' do
        row_time_data = time_data_with_nils
        attribute = :bitkey
        expected = [in_bitkey, in_bitkey, in_bitkey, in_bitkey, in_bitkey, out_bitkey, in_bitkey, in_bitkey]
        event = test_event
        validate_split_time_attribute(row_time_data, attribute, expected, event)
      end
    end

    def validate_split_time_attribute(row_time_data, attribute, expected, event)
      allow(event).to receive(:ordered_splits).and_return(event.splits)
      allow(event).to receive(:sub_splits).and_return(event.splits.map(&:sub_splits).flatten)
      effort = FactoryGirl.build_stubbed(:effort, id: 1001, event: event)
      allow(effort).to receive(:changed?).and_return(false)
      creator = EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                           current_user_id: current_user_id, event: event)
      expect(creator.split_times.map(&attribute)).to eq(expected)
    end
  end
end