# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EffortWithTimesPresenter do
  subject { EffortWithTimesPresenter.new(effort, params: params) }
  let(:effort) { build_stubbed(:effort) }
  let(:params) { ActionController::Parameters.new(params_hash) }
  let(:params_hash) { {} }

  describe '#initialize' do
    context 'given an effort and params object' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'if effort argument is not given' do
      let(:effort) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include a subject/)
      end
    end
  end

  describe '#guaranteed_split_time' do
    let(:split_time_1) { build_stubbed(:split_time, lap: 1, split_id: 101, bitkey: 1) }
    let(:split_time_2) { build_stubbed(:split_time, lap: 1, split_id: 102, bitkey: 1) }
    let(:split_time_3) { build_stubbed(:split_time, lap: 1, split_id: 102, bitkey: 64) }
    let(:split_times) { [split_time_1, split_time_2, split_time_3] }

    before do
      allow(effort).to receive(:split_times).and_return(split_times)
    end

    context 'when the effort has a split_time that corresponds to the provided time_point' do
      let(:time_point) { split_times.last.time_point }

      it 'returns the corresponding split_time' do
        expect(subject.guaranteed_split_time(time_point)).to be_persisted
        expect(subject.guaranteed_split_time(time_point)).to eq(split_times.last)
      end
    end

    context 'when the effort does not have a split_time that corresponds to the provided time_point' do
      let(:time_point) { TimePoint.new(2, 0, 64) }

      it 'returns a new SplitTime object populated with the time_point information and the effort.id' do
        expect(subject.guaranteed_split_time(time_point)).to be_new_record
        expect(subject.guaranteed_split_time(time_point).time_point).to eq(time_point)
        expect(subject.guaranteed_split_time(time_point).effort_id).to eq(effort.id)
        expect(subject.guaranteed_split_time(time_point).time_from_start).to be_nil
      end
    end
  end

  describe '#table_header' do
    context 'when params[:display_style] == military_time' do
      let(:params_hash) { {display_style: 'military_time'} }

      it 'returns a header indicating military times' do
        expect(subject.table_header).to eq('Military Times')
      end
    end

    context 'when params[:display_style] == elapsed_time' do
      let(:params_hash) { {display_style: 'elapsed_time'} }

      it 'returns a header indicating elapsed times' do
        expect(subject.table_header).to eq('Elapsed Times')
      end
    end
  end

  describe '#working_field' do
    context 'when params[:display_style] == elapsed_time' do
      let(:params_hash) { {display_style: 'military_time'} }

      it 'returns :military_time' do
        expect(subject.working_field).to eq(:military_time)
      end
    end

    context 'when params[:display_style] != military_time' do
      let(:params_hash) { {display_style: ''} }

      it 'returns :military_time' do
        expect(subject.working_field).to eq(:military_time)
      end
    end
  end
end
