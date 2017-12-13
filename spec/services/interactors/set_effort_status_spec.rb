require 'rails_helper'

RSpec.describe Interactors::SetEffortStatus do
  before { FactoryGirl.reload }

  subject { Interactors::SetEffortStatus.new(effort, times_container: times_container) }
  let(:event) { build_stubbed(:event_functional, efforts_count: 1) }
  let(:effort) { event.efforts.first }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  describe '#initialize' do
    context 'when an effort is provided' do
      it 'initializes with an effort and a times_container in an args hash' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no effort is provided' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include a subject/)
      end
    end
  end

  describe '#set_data_status' do
    before do
      expect(effort.split_times.map(&:data_status)).to all eq(nil)
      expect(effort.data_status).to eq(nil)
    end

    context 'for an effort that has not yet started' do
      before { allow(effort).to receive(:split_times).and_return([]) }

      it 'sets effort data_status to good and does not attempt to change split_times' do
        subject.perform
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when split_times fall within expected ranges' do
      it 'sets data_status of all split_times and effort to "good"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to all eq('good')
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when one split_time is questionable' do
      before { effort.split_times.second.time_from_start = 2000 }

      it 'sets data_status of all split_times correctly and sets effort to "questionable"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to eq(%w[good questionable good good good good])
        expect(effort.data_status).to eq('questionable')
      end
    end

    context 'when one split_time is questionable and one is bad' do
      before { effort.split_times.second.time_from_start = 100 }
      before { effort.split_times.third.time_from_start = 2000 }

      it 'sets data_status of all split_times correctly and sets effort to "bad"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to eq(%w[good bad questionable good good good])
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'when a split_time has stopped_here: true' do
      before { effort.split_times.third.stopped_here = true }

      it 'sets data_status of all subsequent split_times to "bad"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to eq(%w[good good good bad bad bad])
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'when all split_times are confirmed' do
      before { effort.split_times.third.time_from_start = 100 } # Bad time
      before { effort.split_times.each { |st| st.data_status = :confirmed } }

      it 'sets data_status of the effort to "good"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to all eq('confirmed')
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when split_times have data_status set incorrectly' do
      before do
        effort.split_times.third.time_from_start = 100 # bad time
        pre_set_statuses = %w[bad questionable good questionable good bad]
        effort.split_times.zip(pre_set_statuses).each do |st, status|
          st.data_status = status
        end
      end

      it 'sets data_status of the effort to "good"' do
        subject.perform
        expect(effort.split_times.map(&:data_status)).to eq(%w[good good bad good good good])
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'for a multi-lap event' do
      let(:event) { build_stubbed(:event_functional, splits_count: 3, laps_required: 3, efforts_count: 1) }

      context 'when all times are good' do
        it 'sets all data_status attributes to "good"' do
          subject.perform
          expect(effort.split_times.map(&:data_status)).to all eq('good')
          expect(effort.data_status).to eq('good')
        end
      end

      context 'when not all times are good' do
        before { effort.split_times[6].time_from_start = 100 }

        it 'works as expected' do
          subject.perform
          expect(effort.split_times.map(&:data_status)).to eq(['good'] * 6 + ['bad'] + ['good'] * 5)
          expect(effort.data_status).to eq('bad')
        end
      end
    end
  end
end
