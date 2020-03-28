# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderedEffortsAtTimePoint do
  describe '#initialize' do
    subject { described_class.new(lap: lap, split_id: split_id, sub_split_bitkey: sub_split_bitkey, effort_ids: effort_ids) }
    let(:lap) { 1 }
    let(:split_id) { 101 }
    let(:sub_split_bitkey) { SubSplit::IN_BITKEY }

    context 'when given a Postgres-style array' do
      let(:effort_ids) { '{1001,1003,1005}' }
      it 'casts effort_ids as an array' do
        expect(subject.effort_ids).to eq([1001, 1003, 1005])
      end
    end

    context 'when given an empty Postgres-style array' do
      let(:effort_ids) { '{}' }
      it 'casts as an empty array' do
        expect(subject.effort_ids).to eq([])
      end
    end

    context 'when given an empty string' do
      let(:effort_ids) { '' }
      it 'casts as an empty array' do
        expect(subject.effort_ids).to eq([])
      end
    end

    context 'when given an array' do
      let(:effort_ids) { [1, 2, 3] }
      it 'returns the array' do
        expect(subject.effort_ids).to eq([1, 2, 3])
      end
    end

    context 'when given nil' do
      let(:effort_ids) { nil }
      it 'casts as an empty array' do
        expect(subject.effort_ids).to eq([])
      end
    end
  end

  describe '.execute_query' do
    subject { described_class.execute_query(event.id) }
    context 'when given an event id that has started efforts' do
      let(:event) { events(:hardrock_2015) }
      let(:subject_time_point) { TimePoint.new(1, grouse.id, in_bitkey) }
      let(:grouse) { splits(:hardrock_ccw_grouse) }
      let(:expected_ids_at_grouse_in) { [7, 8, 15, 25, 29, 24, 20, 47, 141, 50, 59, 56, 31, 63, 61, 73, 57, 112, 94, 96, 105, 116, 125, 129, 136, 117, 121, 138] }
      it 'returns rows containing ordered effort ids for all time points' do
        expect(subject.size).to eq(14)
        grouse_oeatp = subject.find { |oeatp| oeatp.time_point == subject_time_point }
        expect(grouse_oeatp.effort_ids).to eq(expected_ids_at_grouse_in)
      end
    end
  end
end
