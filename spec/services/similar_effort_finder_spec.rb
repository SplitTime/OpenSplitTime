# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SimilarEffortFinder, type: :model do
  subject { SimilarEffortFinder.new(time_point: time_point, time_from_start: time_from_start, min: min) }
  let(:time_point) { TimePoint.new(1, 110, 1) }
  let(:time_from_start) { 10000 }
  let(:min) { nil }
  let(:effort_times) { {} }

  before { allow(subject).to receive(:effort_times).and_return(effort_times) }

  describe '#initialize' do
    context 'when provided with a time_point and time_from_start' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#effort_ids' do
    let(:min) { 3 }

    context 'when no efforts meet the provided criteria' do
      let(:effort_times) { {} }

      it 'returns an empty array' do
        expect(subject.effort_ids).to eq([])
      end
    end

    context 'when some efforts meet the provided criteria' do
      let(:effort_times) { {101 => 9000,
                            102 => 10000,
                            103 => 11000,
                            104 => 20000,
                            105 => 21000,
                            106 => 22000} }

      it 'returns an array of effort ids for the elements of #effort_times that meet the provided criteria' do
        expect(subject.effort_ids).to eq([101, 102, 103])
      end
    end

    context 'when many efforts meet the provided criteria' do
      let(:effort_times) { {90 => 6000,
                            91 => 6500,
                            92 => 7000,
                            101 => 9000,
                            102 => 10000,
                            103 => 11000,
                            104 => 13000,
                            105 => 14000,
                            106 => 15000} }

      it 'limits the set of ids to those elements of #effort_times that most closely meet the provided criteria' do
        expect(subject.effort_ids).to eq([101, 102, 103])
      end
    end

    context 'as min: argument increases' do
      let(:effort_times) { {90 => 6000,
                            91 => 6500,
                            92 => 7000,
                            101 => 9000,
                            102 => 10000,
                            103 => 11000,
                            104 => 13000,
                            105 => 14000,
                            106 => 15000} }
      let(:min) { 4 }

      it 'expands to include additional elements of #effort_times' do
        expect(subject.effort_ids).to eq([92, 101, 102, 103, 104])
      end
    end
  end
end
