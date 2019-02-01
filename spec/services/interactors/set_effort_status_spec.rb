# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interactors::SetEffortStatus do
  subject { Interactors::SetEffortStatus.new(effort, times_container: times_container) }
  let(:effort) { efforts(:hardrock_2014_finished_first) }
  let(:subject_split_times) { effort.ordered_split_times }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  before { FactoryBot.reload }

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
      effort.update(data_status: nil)
      subject_split_times.each { |st| st.update(data_status: nil) }
    end

    context 'for an effort that has not yet started' do
      let(:effort) { efforts(:hardrock_2014_not_started) }

      it 'sets effort data_status to good and does not attempt to change split_times' do
        subject.perform
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when split_times fall within expected ranges' do
      let(:effort) { efforts(:hardrock_2014_finished_first) }

      it 'sets data_status of all split_times and effort to "good"' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to all eq('good')
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when one split_time is questionable' do
      let(:split_time) { subject_split_times.second }
      before { split_time.update(absolute_time: split_time.absolute_time - 3.hours) }

      it 'sets data_status of all split_times correctly and sets effort to "questionable"' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to eq(%w[good questionable] + ['good'] * 10)
        expect(effort.data_status).to eq('questionable')
      end
    end

    context 'when one split_time is questionable and one is bad' do
      let(:split_time_1) { subject_split_times.second }
      let(:split_time_2) { subject_split_times.third }

      before { split_time_1.update(absolute_time: split_time_1.absolute_time - 4.hours) }
      before { split_time_2.update(absolute_time: split_time_2.absolute_time - 3.hours) }

      it 'sets data_status of all split_times correctly and sets effort to "bad"' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to eq(%w[good bad questionable] + ['good'] * 9)
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'when a split_time has stopped_here: true' do
      before { subject_split_times.third.update(stopped_here: true) }

      it 'sets data_status of all subsequent split_times to "bad"' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to eq(%w[good good good] + ['bad'] * 9)
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'when all split_times are confirmed' do
      let(:split_time) { subject_split_times.third }
      before { split_time.update(absolute_time: split_time.absolute_time - 4.hours) } # Bad time
      before { subject_split_times.each { |st| st.data_status = :confirmed } }

      it 'sets data_status of the effort to "good"' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to all eq('confirmed')
        expect(effort.data_status).to eq('good')
      end
    end

    context 'when split_times have data_status set incorrectly' do
      let(:split_time) { subject_split_times.third }
      before do
        split_time.update(absolute_time: split_time.absolute_time - 4.hours) # Bad time
        effort.update(data_status: :good)

        pre_set_statuses = %w[bad questionable good questionable good bad] + ['good'] * 6
        subject_split_times.zip(pre_set_statuses).each do |st, status|
          st.update(data_status: status)
        end
      end

      it 'sets data_status of the split_times and effort correctly' do
        subject.perform
        expect(subject_split_times.map(&:data_status)).to eq(%w[good good bad] + ['good'] * 9)
        expect(effort.data_status).to eq('bad')
      end
    end

    context 'for a multi-lap event' do
      let(:effort) { efforts(:rufa_2017_24h_finished_last) }

      context 'when all times are good' do
        it 'sets all data_status attributes to "good"' do
          subject.perform
          expect(subject_split_times.map(&:data_status)).to all eq('good')
          expect(effort.data_status).to eq('good')
        end
      end

      context 'when not all times are good' do
        let(:split_time) { subject_split_times[4] }
        before { split_time.update(absolute_time: split_time.absolute_time - 4.hours) }

        it 'works as expected' do
          subject.perform
          expect(subject_split_times.map(&:data_status)).to eq(['good'] * 4 + ['bad'] + ['good'])
          expect(effort.data_status).to eq('bad')
        end
      end
    end
  end
end
