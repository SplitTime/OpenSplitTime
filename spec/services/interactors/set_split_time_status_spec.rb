require 'rails_helper'

RSpec.describe Interactors::SetSplitTimeStatus do
  before do
    FactoryGirl.reload
  end

  subject { Interactors::SetSplitTimeStatus.new(split_time, effort: effort, times_container: times_container) }
  let(:effort) { event.efforts.first }
  let(:split_times) { effort.ordered_split_times }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe '#initialize' do
    let(:event) { build_stubbed(:event_functional, efforts_count: 1) }

    context 'when a split_time is provided' do
      let(:split_time) { split_times.first }

      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no split_time is provided' do
      let(:split_time) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include a subject/)
      end
    end
  end

  describe '#perform' do
    context 'in a single-lap event' do
      let(:event) { build_stubbed(:event_functional, efforts_count: 1) }

      context 'for a start split_time with time_from_start: 0' do
        let(:split_time) { split_times.first }

        it 'sets data_status to good' do
          subject.perform
          expect(split_time.data_status).to eq('good')
        end
      end

      context 'for a start split_time with time_from_start: non-zero' do
        let(:split_time) { split_times.first }
        before { split_time.time_from_start = 1 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end

      context 'for an intermediate split_time with time_from_start that is reasonable' do
        let(:split_time) { split_times.third }

        it 'sets data_status to good' do
          subject.perform
          expect(split_time.data_status).to eq('good')
        end
      end

      context 'for an intermediate split_time with time_from_start that is reasonable but less than an earlier valid time_from_start' do
        let(:split_time) { split_times.third }
        before { split_times.second.time_from_start = split_time.time_from_start + 1 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end

      context 'for an intermediate split_time with an impossibly short time_from_start' do
        let(:split_time) { split_times.second }
        before { split_time.time_from_start = 100 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end

      context 'for an intermediate split_time with an impossibly long time_from_start' do
        let(:split_time) { split_times.second }
        before { split_time.time_from_start = 100_000 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end

      context 'for an intermediate split_time with an improbably short time_from_start' do
        let(:split_time) { split_times.second }
        before { split_time.time_from_start = 2000 }

        it 'sets data_status to questionable' do
          subject.perform
          expect(split_time.data_status).to eq('questionable')
        end
      end

      context 'for an intermediate split_time with an improbably long time_from_start' do
        let(:split_time) { split_times.second }
        before { split_time.time_from_start = 15_000 }

        it 'sets data_status to questionable' do
          subject.perform
          expect(split_time.data_status).to eq('questionable')
        end
      end

      context 'for an intermediate split_time with a reasonable time from start but impossible time from prior bad time' do
        let(:split_time) { split_times.third }
        before do
          split_times.second.time_from_start = split_time.time_from_start + 1
          split_times.second.data_status = 'bad'
        end

        it 'looks past the bad time to determine validity' do
          subject.perform
          expect(split_time.data_status).to eq('good')
        end
      end

      context 'for time too long in aid' do
        let(:split_time) { split_times.third }
        before { split_time.time_from_start = split_times.second.time_from_start + 26.hours }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end
    end

    context 'in a multi-lap event' do
      let(:event) { build_stubbed(:event_functional, splits_count: 3, laps_required: 3, efforts_count: 1) }

      context 'for a start split_time with time_from_start: 0' do
        let(:split_time) { split_times.first }

        it 'sets data_status to good' do
          subject.perform
          expect(split_time.data_status).to eq('good')
        end
      end

      context 'for a start split_time with time_from_start: non-zero' do
        let(:split_time) { split_times.first }
        before { split_time.time_from_start = 1 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end

      context 'for an intermediate split_time with time_from_start that is reasonable' do
        let(:split_time) { split_times[8] }

        it 'sets data_status to good' do
          subject.perform
          expect(split_time.data_status).to eq('good')
        end
      end

      context 'for an intermediate split_time with time_from_start that is reasonable but less than an earlier valid time_from_start' do
        let(:split_time) { split_times[8] }
        before { split_times[7].time_from_start = split_time.time_from_start + 1 }

        it 'sets data_status to bad' do
          subject.perform
          expect(split_time.data_status).to eq('bad')
        end
      end
    end
  end
end
