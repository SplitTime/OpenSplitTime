require 'rails_helper'

RSpec.describe EffortSplitTimeCreator, type: :model do
  let(:excel_epoch) { '1899-12-30'.to_datetime }
  let(:event) { double(:event,
                       start_time: DateTime.new(2016, 7, 1, 6).in_time_zone,
                       sub_split_bitkey_hashes: [{101 => 1}, {102 => 1}, {102 => 64}, {103 => 1}, {103 => 64}, {104 => 1}]) }
  let(:effort) { double(:effort, id: 1001, event: event, full_name: 'John Appleseed') }
  let(:current_user_id) { 1 }

  describe 'initialize' do
    it 'properly calculates start_offset and dropped_split_id from empty row data' do
      row_time_data = Array.new(6)
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(0)
      expect(creator.dropped_split_id).to be_nil
    end

    it 'properly calculates start_offset and dropped_split_id from a populated row' do
      row_time_data = [excel_epoch, excel_epoch + 1.hour, excel_epoch + 1.hour, excel_epoch + 3.hours, nil, nil]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(0)
      expect(creator.dropped_split_id).to eq(103)
    end

    it 'properly calculates start_offset and dropped_split_id from another populated row' do
      row_time_data = [30.minutes.to_i, 90.minutes.to_i, 95.minutes.to_i,
                       300.minutes.to_i, 310.minutes.to_i, nil]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(30.minutes)
      expect(creator.dropped_split_id).to eq(103)
    end

    it 'properly calculates negative start_offset and dropped_split_id from another populated row' do
      row_time_data = [-30.minutes.to_i, 90.minutes.to_i, nil, nil, nil, nil]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(-30.minutes)
      expect(creator.dropped_split_id).to eq(102)
    end

    it 'sets dropped_split_id to last existing time regardless of interim gaps' do
      row_time_data = [0, nil, 3000, nil, 5000, nil]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(0)
      expect(creator.dropped_split_id).to eq(103)
    end

    it 'sets dropped_split_id to nil when row is fully populated' do
      row_time_data = [0, 1000, 2000, 3000, 4000, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(0)
      expect(creator.dropped_split_id).to be_nil
    end

    it 'sets dropped_split_id to nil if interim times are missing but finish time exists' do
      row_time_data = [0, 1000, nil, 3000, nil, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(0)
      expect(creator.dropped_split_id).to be_nil
    end

    it 'raises an ArgumentError if row_time_data and event sub_split count do not match' do
      row_time_data = [0, 1000, nil, 3000]
      expect { EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event) }
          .to raise_error(ArgumentError)
    end
  end

  describe 'split_times' do
    it 'returns an array of SplitTime objects the same number as is contained in row_time_data' do
      row_time_data = [0, 1000, nil, 3000, nil, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.count).to eq(4)
      expect(creator.split_times.map(&:class)).to eq([SplitTime] * 4)
    end

    it 'sets effort_ids uniformly to the id of the effort parameter' do
      row_time_data = [0, 1000, 2000, 3000, 4000, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:effort_id)).to eq([1001] * 6)
    end

    it 'sets split_ids properly based on existing times provided' do
      row_time_data = [0, nil, nil, 3000, nil, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:split_id)).to eq([101, 103, 104])
    end

    it 'sets bitkeys properly based on existing times provided' do
      row_time_data = [0, nil, 2000, 3000, nil, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:sub_split_bitkey)).to eq([SubSplit::IN_BITKEY, SubSplit::OUT_BITKEY,
                                                                 SubSplit::IN_BITKEY, SubSplit::IN_BITKEY])
    end

    it 'sets time_from_start properly based on existing time data provided' do
      row_time_data = [0, 1000, nil, 3000, nil, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1000, 3000, 5000])
    end

    it 'sets the start time to zero after setting start_offset' do
      row_time_data = [500, 1000, 2000, 3000, 4000, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.start_offset).to eq(500)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1000, 2000, 3000, 4000, 5000])
    end

    it 'understands time data provided as integer seconds elapsed' do
      row_time_data = [0, 1000, 2000, 3000, 4000, 5000]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1000, 2000, 3000, 4000, 5000])
    end

    it 'understands time data provided as float seconds elapsed' do
      row_time_data = [0.0, 1000.0, 2000.0, 3000.0, 4000.0, 5000.0]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1000, 2000, 3000, 4000, 5000])
    end

    it 'understands time data provided as Excel date values' do
      row_time_data = [excel_epoch, excel_epoch + 1.hour, excel_epoch + 2.hours,
                       excel_epoch + 3.hours, excel_epoch + 4.hours, excel_epoch + 5.hours]
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours])
    end

    it 'understands elapsed time string data formatted as h:mm:ss' do
      skip
      row_time_data = %w(0:00:00 1:00:00 2:00:00 3:00:00 4:00:00 5:00:00)
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours])
    end

    it 'understands elapsed time string data formatted as h:mm' do
      skip
      row_time_data = %w(0:00 1:00 2:00 3:00 4:00 5:00)
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 1.hour, 2.hours, 3.hours, 4.hours, 5.hours])
    end

    it 'understands elapsed time string data with values greater than 24 hours' do
      skip
      row_time_data = %w(0:00 10:00 20:00 30:00 40:00 50:00)
      creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
      expect(creator.split_times.map(&:time_from_start)).to eq([0, 10.hours, 20.hours, 30.hours, 40.hours, 50.hours])
    end
  end
end