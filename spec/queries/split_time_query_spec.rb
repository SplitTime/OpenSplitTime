# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions
include FeatureMacros

RSpec.describe SplitTimeQuery do
  let(:lap_1) { 1 }

  describe '.typical_segment_time' do
    subject { SplitTimeQuery.typical_segment_time(segment, effort_ids) }
    let(:count) { subject[:effort_count] }
    let(:time) { subject[:average] }

    before do
      FactoryBot.reload
      course = create(:course)
      splits = create_list(:splits_hardrock_ccw, 3, course: course)
      event = create(:event, course: course)
      event.splits << splits
      efforts = create_list(:efforts_hardrock, 4, event: event)
      split_time_simulations = [:split_times_hardrock_45, :split_times_hardrock_43, :split_times_hardrock_41, :split_times_hardrock_38]
      efforts.zip(split_time_simulations).each do |effort, simulation|
        split_times = create_list(simulation, 5, effort: effort, data_status: 2)
        effort.split_times << split_times
      end
      expect(Course.all.size).to eq(1)
      expect(Split.all.size).to eq(3)
      expect(Event.all.size).to eq(1)
      expect(Effort.all.size).to eq(4)
      expect(SplitTime.all.size).to eq(20)
    end

    let(:start_split) { Split.find_by(base_name: 'Start') }
    let(:cunningham_split) { Split.find_by(base_name: 'Cunningham') }
    let(:maggie_split) { Split.find_by(base_name: 'Maggie') }
    let(:start) { TimePoint.new(lap_1, start_split.id, in_bitkey) }
    let(:cunningham_in) { TimePoint.new(lap_1, cunningham_split.id, in_bitkey) }
    let(:maggie_in) { TimePoint.new(lap_1, maggie_split.id, in_bitkey) }
    let(:maggie_out) { TimePoint.new(lap_1, maggie_split.id, out_bitkey) }
    let(:start_to_cunningham_in) { Segment.new(begin_point: start, end_point: cunningham_in) }
    let(:in_aid_maggie) { Segment.new(begin_point: maggie_in, end_point: maggie_out) }

    context 'for a course segment' do
      let(:segment) { start_to_cunningham_in }
      let(:effort_ids) { nil }

      it 'returns average time and count' do
        expect(time).to be_within(100).of(10000)
        expect(count).to eq(4)
      end
    end

    context 'if data_status of either the begin or end time is bad or questionable' do
      let(:segment) { in_aid_maggie }
      let(:effort_ids) { nil }

      before do
        effort_1 = Effort.first
        effort_2 = Effort.second
        split_time_1 = SplitTime.find_by(split: maggie_split, sub_split_bitkey: in_bitkey, effort: effort_1)
        split_time_2 = SplitTime.find_by(split: maggie_split, sub_split_bitkey: out_bitkey, effort: effort_2)
        split_time_1.bad!
        split_time_2.questionable!
      end

      it 'ignores any time' do
        expect(count).to eq(2)
      end
    end

    context 'when effort_ids are provided' do
      let(:segment) { in_aid_maggie }
      let(:effort_ids) { Effort.all.ids.first(2) }

      it 'limits the scope of the query' do
        expect(time).to be_within(50).of(200)
        expect(count).to eq(2)
      end
    end
  end

  describe '.split_traffic' do
    subject { ActiveRecord::Base.connection.execute(query) }
    let(:query) { SplitTimeQuery.split_traffic(event_group: event_group, split_name: split_name, band_width: band_width) }
    let(:event_group) { EventGroup.first }

    before do
      FactoryBot.reload
      create_hardrock_event
    end
    after { clean_up_database }

    context 'for a split close to the start' do
      let(:split_name) { 'Cunningham' }
      let(:band_width) { 1.hour }

      it 'returns a hash with time intervals and effort counts in and out' do
        expect(subject.cmd_status).to eq('SELECT 2')
        result = subject.to_a
        expect(result.size).to eq(2)
        expect(result.map { |row| row['start_time'] }).to eq(['Fri 08:00', 'Fri 09:00'])
        expect(result.map { |row| row['end_time'] }).to eq(['Fri 09:00', 'Fri 10:00'])
        expect(result.map { |row| row['in_count'] }).to eq([6, 1])
        expect(result.map { |row| row['out_count'] }).to eq([6, 1])
      end
    end

    context 'for a split extending over multiple days' do
      let(:split_name) { 'Engineer' }
      let(:band_width) { 1.hour }

      it 'returns a hash with time intervals reflecting multiple days' do
        expect(subject.cmd_status).to eq('SELECT 7')
        result = subject.to_a
        expect(result.size).to eq(7)
        expect(result.map { |row| row['start_time'] }).to eq(['Fri 19:00', 'Fri 20:00', 'Fri 21:00', 'Fri 22:00', 'Fri 23:00', 'Sat 00:00', 'Sat 01:00'])
        expect(result.map { |row| row['end_time'] }).to eq(['Fri 20:00', 'Fri 21:00', 'Fri 22:00', 'Fri 23:00', 'Sat 00:00', 'Sat 01:00', 'Sat 02:00'])
        expect(result.map { |row| row['in_count'] }).to eq([1, 3, 0, 1, 1, 0, 1])
        expect(result.map { |row| row['out_count'] }).to eq([1, 2, 1, 1, 1, 0, 1])
      end
    end

    context 'for a split with leading or trailing intervals having 0 count' do
      let(:split_name) { 'Cunningham' }
      let(:band_width) { 30.minutes }

      it 'eliminates the leading and trailing intervals' do
        expect(subject.cmd_status).to eq('SELECT 3')
        result = subject.to_a
        expect(result.size).to eq(3)
        expect(result.map { |row| row['start_time'] }).to eq(['Fri 08:00', 'Fri 08:30', 'Fri 09:00'])
        expect(result.map { |row| row['end_time'] }).to eq(['Fri 08:30', 'Fri 09:00', 'Fri 09:30'])
        expect(result.map { |row| row['in_count'] }).to eq([4, 2, 1])
        expect(result.map { |row| row['out_count'] }).to eq([4, 2, 1])
      end
    end
  end
end
