# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interactors::StartEfforts do
  include BitkeyDefinitions

  describe '.perform!' do
    subject { Interactors::StartEfforts.new(efforts: subject_efforts, start_time: start_time, current_user_id: current_user_id) }
    let(:current_user_id) { rand(1..100) }
    let(:home_time_zone) { subject_efforts.first.home_time_zone }

    context 'when all provided efforts are valid' do
      context 'when no efforts have a starting split time' do
        let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_not_started)] }

        context 'when start_time is provided as a string with no time zone' do
          let(:start_time) { '2017-09-23 08:00:00' }

          it 'creates start split_times for each effort, assigns user_id to created_by, and returns a successful response' do
            expect(subject_efforts.map(&:starting_split_time)).to all be_nil
            response = subject.perform!

            expect(response).to be_successful
            expect(response.message).to eq('Started 2 efforts')

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times).to all be_present
            expect(split_times.map(&:created_by)).to all eq(current_user_id)
            expect(split_times.map(&:absolute_time)).to all eq(start_time.in_time_zone(home_time_zone))
          end
        end

        context 'when start_time is a valid date string with time zone information' do
          let(:start_time) { '2017-09-23 08:00:00 EDT' }

          it 'creates start split_times for each effort' do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.map(&:absolute_time)).to all eq('2017-09-23 08:00:00'.in_time_zone('Eastern Time (US & Canada)'))
          end
        end

        context 'when start_time is provided as a datetime object' do
          let(:start_time) { '2017-09-23 08:00:00'.in_time_zone(home_time_zone) }

          it 'creates start split_times for each effort' do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.map(&:absolute_time)).to all eq(start_time.in_time_zone(home_time_zone))
          end
        end

        context 'when start_time is not provided' do
          let(:start_time) { nil }

          before do
            subject_efforts.first.update(scheduled_start_time: '2017-09-23 11:00:00'.in_time_zone(home_time_zone))
            subject_efforts.second.update(scheduled_start_time: nil)
          end

          it 'creates start split_times using scheduled_start_time when available or event_start_time otherwise' do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.first.absolute_time).to eq(subject_efforts.first.scheduled_start_time)
            expect(split_times.second.absolute_time).to eq(subject_efforts.second.event_start_time)
          end
        end

        context 'when start_time is an empty string' do
          let(:start_time) { '' }

          before do
            subject_efforts.first.update(scheduled_start_time: '2017-09-23 11:00:00'.in_time_zone(home_time_zone))
            subject_efforts.second.update(scheduled_start_time: nil)
          end

          it 'creates start split_times using scheduled_start_time when available or event_start_time otherwise' do
            response = subject.perform!

            expect(response).to be_successful

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.first.absolute_time).to eq(subject_efforts.first.scheduled_start_time)
            expect(split_times.second.absolute_time).to eq(subject_efforts.second.event_start_time)
          end
        end

        context 'when start_time is provided but is not a parsable datetime' do
          let(:start_time) { 'hello' }

          it 'creates start split_times using scheduled_start_time when available or event_start_time otherwise' do
            response = subject.perform!

            expect(response).not_to be_successful
            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times).to all be_nil
          end
        end
      end

      context 'when one effort has an existing starting split time' do
        let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_progress_rolling)] }
        let(:start_time) { '2017-09-23 08:00:00' }

        it 'creates starting split_times only for the effort that needs one, and returns a successful response' do
          effort_2_start_time = subject_efforts.second.starting_split_time.absolute_time
          expect { subject.perform! }.to change { SplitTime.count }.by(1)

          subject_efforts.each(&:reload)
          split_times = subject_efforts.map(&:starting_split_time)
          expect(split_times).to all be_present
          expect(split_times.first.absolute_time).to eq(start_time.in_time_zone(home_time_zone))
          expect(split_times.second.absolute_time).to eq(effort_2_start_time)
        end
      end
    end
  end
end
