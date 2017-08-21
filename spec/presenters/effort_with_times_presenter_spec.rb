require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortWithTimesPresenter do
  subject { EffortWithTimesPresenter.new(effort: effort, params: params) }
  let(:effort) { build_stubbed(:effort) }
  let(:params) { ActionController::Parameters.new(params_hash) }
  let(:params_hash) { {} }

  describe '#initialize' do
    it 'initializes given an effort and params object' do
      expect { subject }.not_to raise_error
    end

    it 'raises an error if effort argument is not given' do
      expect { EffortWithTimesPresenter.new(params: params) }
          .to raise_error(/must include effort/)
    end

    it 'raises an error if any argument other than effort and params is given' do
      expect { EffortWithTimesPresenter.new(effort: effort, params: params, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#guaranteed_split_time' do
    let(:split_times) { build_stubbed_list(:split_times_in_out, 3) }

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
    context 'when params[:display_style] == military_times' do
      let(:params_hash) { {display_style: 'military_times'} }

      it 'returns a header indicating times of day' do
        expect(subject.table_header).to eq('Times of Day')
      end
    end

    context 'when params[:display_style] != military_times' do
      let(:params_hash) { {display_style: ''} }

      it 'returns a header indicating elapsed times' do
        expect(subject.table_header).to eq('Elapsed Times')
      end
    end
  end

  describe '#working_field' do
    context 'when params[:display_style] == military_times' do
      let(:params_hash) { {display_style: 'military_times'} }

      it 'returns :military_time' do
        expect(subject.working_field).to eq(:military_time)
      end
    end

    context 'when params[:display_style] != military_times' do
      let(:params_hash) { {display_style: ''} }

      it 'returns :elapsed_time' do
        expect(subject.working_field).to eq(:elapsed_time)
      end
    end
  end
end
