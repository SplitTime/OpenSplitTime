require 'rails_helper'

RSpec.describe SplitTimeFinder do
  subject { SplitTimeFinder.new(effort: effort, time_point: time_point, lap_splits: lap_splits, split_times: split_times, valid: valid) }
  let(:effort) { event.efforts.first }
  let(:time_point) { time_points.last }
  let(:lap_splits) { event.lap_splits_through(laps_required) }
  let(:split_times) { effort&.split_times }
  let(:valid) { nil }
  let(:event) { build_stubbed(:event_functional, laps_required: laps_required, splits_count: 3, efforts_count: 1) }
  let(:laps_required) { 3 }
  let(:time_points) { event.time_points_through(laps_required) }

  describe '#initialize' do
    context 'with an effort, a time_point, lap_splits, and split_times in an args hash' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when neither effort nor lap_splits is given' do
      let(:effort) { nil }
      let(:lap_splits) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include one of effort or lap_splits/)
      end
    end

    context 'when no time_point is given' do
      let(:time_point) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include time_point/)
      end
    end
  end

  describe '#prior' do
    context 'when args[:valid] is true' do
      let(:valid) { true }

      context 'when all prior split_times are valid' do
        let(:time_point) { time_points[5] }

        it 'returns the split_time that comes immediately prior to the provided time_point' do
          expect(subject.prior).to eq(split_times[4])
        end
      end

      context 'when some prior split_times are invalid' do
        let(:time_point) { time_points[5] }

        before do
          split_times[3].data_status = 'bad'
          split_times[4].data_status = 'questionable'
        end

        it 'returns the latest valid split_time that comes prior to the provided time_point' do
          expect(subject.prior).to eq(split_times[2])
        end
      end

      context 'when all prior split_times are invalid' do
        let(:time_point) { time_points[2] }

        before do
          split_times[0].data_status = 'bad'
          split_times[1].data_status = 'questionable'
        end

        it 'returns nil' do
          expect(subject.prior).to be_nil
        end
      end

      context 'when the starting time_point is provided' do
        let(:time_point) { time_points[0] }

        it 'returns nil' do
          expect(subject.prior).to be_nil
        end
      end
    end

    context 'when args[:valid] is nil' do
      let(:valid) { nil }

      context 'when some prior split_times are invalid' do
        let(:time_point) { time_points[5] }

        before do
          split_times[3].data_status = 'bad'
          split_times[4].data_status = 'questionable'
        end

        it 'behaves as though args[:valid] were true' do
          expect(subject.prior).to eq(split_times[2])
        end
      end
    end

    context 'when args[:valid] is false' do
      let(:valid) { false }

      context 'when all split_times are valid' do
        let(:time_point) { time_points[5] }

        it 'returns the split_time that comes immediately prior to the provided time_point' do
          expect(subject.prior).to eq(split_times[4])
        end
      end

      context 'when some split_times are invalid' do
        let(:time_point) { time_points[5] }

        before do
          split_times[4].data_status = 'questionable'
          split_times[3].data_status = 'bad'
        end

        it 'returns the split_time that comes immediately prior to the provided time_point' do
          expect(subject.prior).to eq(split_times[4])
        end
      end
    end
  end

  describe '#next' do
    context 'when args[:valid] is not provided' do
      let(:valid) { nil }

      context 'when all split_times are valid' do
        let(:time_point) { time_points[5] }

        it 'returns the split_time that comes immediately after to the provided time_point' do
          expect(subject.next).to eq(split_times[6])
        end
      end

      context 'when some later split_times are invalid' do
        let(:time_point) { time_points[5] }

        before do
          split_times[6].data_status = 'bad'
          split_times[7].data_status = 'questionable'
        end

        it 'returns the first valid split_time that comes after the provided time_point' do
          expect(subject.next).to eq(split_times[8])
        end
      end

      context 'when all later split_times are invalid' do
        let(:time_point) { time_points[-3] }

        before do
          split_times[-1].data_status = 'bad'
          split_times[-2].data_status = 'questionable'
        end

        it 'returns nil' do
          expect(subject.next).to be_nil
        end
      end

      context 'when the ending time_point is provided' do
        let(:time_point) { time_points[-1] }

        it 'returns nil' do
          expect(subject.next).to be_nil
        end
      end
    end

    context 'when args[:valid] is false' do
      let(:valid) { false }

      context 'when all split_times are valid' do
        let(:time_point) { time_points[5] }

        it 'returns the split_time that comes immediately after the provided time_point' do
          expect(subject.next).to eq(split_times[6])
        end
      end

      context 'when some later split_times are invalid' do
        let(:time_point) { time_points[5] }

        before do
          split_times[6].data_status = 'questionable'
          split_times[7].data_status = 'bad'
        end

        it 'returns the split_time that comes immediately after the provided time_point' do
          expect(subject.next).to eq(split_times[6])
        end
      end
    end
  end

  describe '#guaranteed_prior' do
    let(:start_time) { event.start_time }

    context 'when a prior split_time exists' do
      let(:time_point) { time_points[5] }

      it 'returns the split_time that comes immediately prior to the provided time_point' do
        expect(subject.guaranteed_prior).to eq(split_times[4])
      end
    end

    context 'when all prior split_times are invalid' do
      let(:time_point) { time_points[2] }

      before do
        split_times[0].data_status = 'bad'
        split_times[1].data_status = 'questionable'
      end

      it 'returns a mock start split_time associated with the provided effort' do
        expected = SplitTime.new(time_point: time_points.first, absolute_time: start_time, effort_id: effort.id)
        expect(subject.guaranteed_prior.attributes).to eq(expected.attributes)
      end
    end

    context 'when the starting time_point is provided' do
      let(:time_point) { time_points[0] }

      it 'returns a mock start split_time associated with the provided effort' do
        expected = SplitTime.new(time_point: time_points.first, absolute_time: start_time, effort_id: effort.id)
        expect(subject.guaranteed_prior.attributes).to eq(expected.attributes)
      end
    end
  end
end
