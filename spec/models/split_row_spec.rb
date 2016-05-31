require 'rails_helper'
require 'pry-byebug'

RSpec.describe SplitRow, type: :model do

  before do

    @course = Course.create!(name: 'Test Course 100')
    @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

    @effort1 = Effort.create!(event: @event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
    @effort2 = Effort.create!(event: @event, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
    @effort3 = Effort.create!(event: @event, bib_number: 3, start_offset: 3600, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male')

    @split1 = Split.create!(course: @course, base_name: 'Starting Line', distance_from_start: 0, sub_split_mask: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
    @split2 = Split.create!(course: @course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_mask: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
    @split4 = Split.create!(course: @course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_mask: 73, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
    @split6 = Split.create!(course: @course, base_name: 'Finish Line', distance_from_start: 25000, sub_split_mask: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

    @event.splits << @course.splits

    @split_time1 = SplitTime.create!(effort: @effort1, split: @split1, sub_split_key: SubSplit::IN_KEY, time_from_start: 0, data_status: 2)
    @split_time2 = SplitTime.create!(effort: @effort1, split: @split2, sub_split_key: SubSplit::IN_KEY, time_from_start: 4000, data_status: 2)
    @split_time3 = SplitTime.create!(effort: @effort1, split: @split2, sub_split_key: SubSplit::OUT_KEY, time_from_start: 4100, data_status: 2)
    @split_time4 = SplitTime.create!(effort: @effort1, split: @split4, sub_split_key: SubSplit::IN_KEY, time_from_start: 15200, data_status: 2)
    @split_time6 = SplitTime.create!(effort: @effort1, split: @split4, sub_split_key: SubSplit::OUT_KEY, time_from_start: 15100, data_status: 0)
    @split_time7 = SplitTime.create!(effort: @effort1, split: @split6, sub_split_key: SubSplit::IN_KEY, time_from_start: 21000, data_status: 2)

    @split_time8 = SplitTime.create!(effort: @effort2, split: @split1, sub_split_key: SubSplit::IN_KEY, time_from_start: 0, data_status: 2)
    @split_time9 = SplitTime.create!(effort: @effort2, split: @split2, sub_split_key: SubSplit::OUT_KEY, time_from_start: 120, data_status: 0)
    @split_time10 = SplitTime.create!(effort: @effort2, split: @split4, sub_split_key: SubSplit::IN_KEY, time_from_start: 24000, data_status: 2)
    @split_time12 = SplitTime.create!(effort: @effort2, split: @split4, sub_split_key: SubSplit::OUT_KEY, time_from_start: 150000, data_status: 0)
    @split_time13 = SplitTime.create!(effort: @effort2, split: @split6, sub_split_key: SubSplit::IN_KEY, time_from_start: 40000, data_status: 1)

    @split_time14 = SplitTime.create!(effort: @effort3, split: @split1, sub_split_key: SubSplit::IN_KEY, time_from_start: 0, data_status: 2)
    @split_time15 = SplitTime.create!(effort: @effort3, split: @split2, sub_split_key: SubSplit::IN_KEY, time_from_start: 5000, data_status: 2)
    @split_time16 = SplitTime.create!(effort: @effort3, split: @split2, sub_split_key: SubSplit::OUT_KEY, time_from_start: 5000, data_status: 2)
    @split_time17 = SplitTime.create!(effort: @effort3, split: @split4, sub_split_key: SubSplit::IN_KEY, time_from_start: 12200, data_status: 2)

    @split_row1 = SplitRow.new(@split1, [@split_time1], nil)
    @split_row2 = SplitRow.new(@split2, [@split_time2, @split_time3], 0)
    @split_row3 = SplitRow.new(@split4, [@split_time4, @split_time6], 4100)
    @split_row4 = SplitRow.new(@split6, [@split_time7], 15100)

    @split_row5 = SplitRow.new(@split1, [@split_time8], nil)
    @split_row6 = SplitRow.new(@split2, [nil, @split_time9], 0)
    @split_row7 = SplitRow.new(@split4, [@split_time10, @split_time12], nil)
    @split_row8 = SplitRow.new(@split6, [@split_time13], 150000)

    @split_row9 = SplitRow.new(@split1, [@split_time14], nil)
    @split_row10 = SplitRow.new(@split2, [@split_time15, @split_time16], 0)
    @split_row11 = SplitRow.new(@split4, [@split_time17, nil, nil], 5000)
    @split_row12 = SplitRow.new(@split6, [nil, nil], 12200)

  end

  describe 'initialization' do

    it 'should instantiate new objects properly' do
      expect(@split_row1.present?).to eq(true)
      expect(@split_row4.present?).to eq(true)
      expect(@split_row6.present?).to eq(true)
      expect(@split_row10.present?).to eq(true)
    end

    it 'should instantiate a SplitRow even if no split_times are provided' do
      expect(@split_row12.present?).to eq(true)
    end

  end

  describe 'times_from_start' do

    it 'should return an array of times_from_start' do
      expect(@split_row1.times_from_start).to eq([0])
      expect(@split_row2.times_from_start).to eq([4000, 4100])
      expect(@split_row3.times_from_start).to eq([15200, 15100])
      expect(@split_row4.times_from_start).to eq([21000])
      expect(@split_row6.times_from_start).to eq([nil, 120])
      expect(@split_row11.times_from_start).to eq([12200, nil])
      expect(@split_row12.times_from_start).to eq([nil, nil])
    end

  end

  describe 'days_and_times' do

    it 'should return an array of datetime values based on event start_time and effort start_offset' do
      event_start_time = @event.start_time
      effort_start_offset = @effort3.start_offset
      expect(@split_row1.days_and_times).to eq([event_start_time])
      expect(@split_row2.days_and_times).to eq([event_start_time + 4000, event_start_time + 4100])
      expect(@split_row4.days_and_times).to eq([event_start_time + 21000])
      expect(@split_row6.days_and_times).to eq([nil, event_start_time + 120])
      expect(@split_row9.days_and_times).to eq([event_start_time + effort_start_offset])
      expect(@split_row10.days_and_times).to eq([event_start_time + effort_start_offset + 5000, event_start_time + effort_start_offset + 5000])
      expect(@split_row11.days_and_times).to eq([event_start_time + effort_start_offset + 12200, nil, nil])
      expect(@split_row12.days_and_times).to eq([nil, nil])
    end
    
  end

  describe 'time_data_statuses' do

    it 'should return an array of data statuses' do
      expect(@split_row1.time_data_statuses).to eq(['good'])
      expect(@split_row2.time_data_statuses).to eq(['good', 'good'])
      expect(@split_row3.time_data_statuses).to eq(['good', 'good', 'bad'])
      expect(@split_row4.time_data_statuses).to eq(['good'])
      expect(@split_row6.time_data_statuses).to eq([nil, 'bad'])
      expect(@split_row8.time_data_statuses).to eq(['questionable'])
      expect(@split_row11.time_data_statuses).to eq(['good', nil, nil])
      expect(@split_row12.time_data_statuses).to eq([nil, nil])
    end
    
  end
  
  describe 'data_status' do
    
    it 'should return the worst of the time_data_statuses in the split_row' do
      expect(@split_row1.data_status).to eq('good')
      expect(@split_row2.data_status).to eq('good')
      expect(@split_row3.data_status).to eq('bad')
      expect(@split_row4.data_status).to eq('good')
      expect(@split_row6.data_status).to eq('bad')
      expect(@split_row8.data_status).to eq('questionable')
      expect(@split_row11.data_status).to eq(nil)
      expect(@split_row12.data_status).to eq(nil)
    end
    
  end

  describe 'segment_time' do

    it 'should return nil when prior_time is nil' do
      expect(@split_row1.segment_time).to be_nil
      expect(@split_row5.segment_time).to be_nil
      expect(@split_row7.segment_time).to be_nil
      expect(@split_row9.segment_time).to be_nil
    end
    
    it 'should return nil when times_from_start contains only nil values' do
      expect(@split_row12.segment_time).to be_nil
    end

    it 'should return the correct segment_time when prior_time is provided and at least one time_from_start is available' do
      expect(@split_row2.segment_time).to eq(4000)
      expect(@split_row3.segment_time).to eq(11100)
      expect(@split_row4.segment_time).to eq(5900)
      expect(@split_row11.segment_time).to eq(7200)
    end

  end

  describe 'time_in_aid' do
    
    it 'should return nil when fewer than two split_times are provided' do
      expect(@split_row1.time_in_aid).to be_nil
      expect(@split_row4.time_in_aid).to be_nil
      expect(@split_row6.time_in_aid).to be_nil
      expect(@split_row11.time_in_aid).to be_nil
    end
    
    it 'should return the time difference between first and last split_times when two or more are provided' do
      expect(@split_row2.time_in_aid).to eq(100)
      expect(@split_row3.time_in_aid).to eq(-100)
      expect(@split_row7.time_in_aid).to eq(150000 - 24000)
    end
    
  end
  
end