# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe SplitTimeQuery do
  let(:lap_1) { 1 }

  describe '.typical_segment_time' do
    subject { SplitTimeQuery.typical_segment_time(segment, effort_ids) }
    let(:count) { subject[:effort_count] }
    let(:time) { subject[:average] }

    let(:course) { courses(:hardrock_ccw) }
    let(:start_split) { course.splits.find_by(base_name: 'Start') }
    let(:cunningham_split) { course.splits.find_by(base_name: 'Cunningham') }
    let(:sherman_split) { course.splits.find_by(base_name: 'Sherman') }
    let(:start) { TimePoint.new(lap_1, start_split.id, in_bitkey) }
    let(:cunningham_in) { TimePoint.new(lap_1, cunningham_split.id, in_bitkey) }
    let(:sherman_in) { TimePoint.new(lap_1, sherman_split.id, in_bitkey) }
    let(:sherman_out) { TimePoint.new(lap_1, sherman_split.id, out_bitkey) }
    let(:start_to_cunningham_in) { Segment.new(begin_point: start, end_point: cunningham_in) }
    let(:in_aid_sherman) { Segment.new(begin_point: sherman_in, end_point: sherman_out) }

    context 'for a course segment' do
      let(:segment) { start_to_cunningham_in }
      let(:effort_ids) { nil }

      it 'returns average time and count' do
        expect(time).to be_within(100).of(9550)
      end
    end

    context 'when effort_ids are provided' do
      let(:event) { events(:hardrock_2015) }
      let(:segment) { in_aid_sherman }
      let(:effort_ids) { event.efforts.order(:bib_number).ids.first(2) }

      it 'limits the scope of the query' do
        expect(count).to eq(2)
        expect(time).to be_within(100).of(300)
      end
    end
  end

  describe '.split_traffic' do
    subject { ActiveRecord::Base.connection.execute(query) }
    let(:query) { SplitTimeQuery.split_traffic(event_group: event_group, split_name: split_name, band_width: band_width) }
    let(:event_group) { event_groups(:hardrock_2015) }

    context 'for a split close to the start' do
      let(:split_name) { 'Cunningham' }
      let(:band_width) { 1.hour }

      it 'returns a hash with time intervals and effort counts in and out' do
        expect(subject.cmd_status).to eq('SELECT 3')
        result = subject.to_a

        expect(result.size).to eq(3)
        expect(result.map { |row| row['start_time'] }).to eq(['Fri 07:00', 'Fri 08:00', 'Fri 09:00'])
        expect(result.map { |row| row['end_time'] }).to eq(['Fri 08:00', 'Fri 09:00', 'Fri 10:00'])
        expect(result.map { |row| row['in_count'] }).to eq([2, 20, 8])
        expect(result.map { |row| row['out_count'] }).to eq([2, 20, 8])
      end
    end

    context 'for a split extending over multiple days' do
      let(:split_name) { 'Telluride' }
      let(:band_width) { 1.hour }

      it 'returns a hash with time intervals reflecting multiple days' do
        expect(subject.cmd_status).to eq('SELECT 19')
        result = subject.to_a

        expect(result.size).to eq(19)
        expect(result[10]).to eq({'start_time' => 'Sat 07:00',
                                  'end_time' => 'Sat 08:00',
                                  'in_count' => 5,
                                  'out_count' => 4,
                                  'finished_in_count' => 5,
                                  'finished_out_count' => 4})
      end
    end
  end
end
