require 'rails_helper'

RSpec.describe Interactors::StartEfforts do
  include BitkeyDefinitions

  describe '.perform!' do
    subject { Interactors::StartEfforts.new(efforts: efforts, start_time: start_time, current_user_id: current_user_id) }
    let(:start_time) { event.start_time + rand(-500..500).minutes }
    let(:current_user_id) { rand(1..100) }

    context 'when all provided efforts are valid' do
      let(:efforts) { create_list(:effort, 2, event: event) }
      let(:event) { create(:event, course: course) }
      let(:start_split) { create(:split, :start, course: course) }
      let(:course) { create(:course) }

      before do
        allow(event).to receive(:start_split).and_return(start_split)
      end

      context 'when no efforts have a starting split time' do
        it 'creates start split_times for each effort, assigns user_id to created_by, and returns a successful response' do
          response = subject.perform!
          expect(SplitTime.count).to eq(2)
          expect(SplitTime.all.map(&:created_by)).to all eq(current_user_id)
          expect(response).to be_successful
          expect(response.message).to eq('Started 2 efforts')
        end
      end

      context 'when one effort has an existing starting split time' do
        let!(:existing_starting_split_time) { create(:split_time, effort: efforts.first, lap: 1, split: start_split, bitkey: in_bitkey) }

        it 'creates starting split_times only for the effort that needs one, and returns a successful response' do
          expect(SplitTime.count).to eq(1)
          existing_start_time = existing_starting_split_time.absolute_time
          response = subject.perform!
          expect(SplitTime.count).to eq(2)
          existing_starting_split_time.reload
          expect(existing_starting_split_time.absolute_time).to eq(existing_start_time)
          expect(response).to be_successful
          expect(response.message).to eq('Started 1 effort')
        end
      end

      context 'when start_time is a valid date string with time zone information' do
        let(:start_time) { '2018-10-31 08:00:00 -0500' }

        it 'creates start split_times for each effort using the provided time zone' do
          response = subject.perform!
          expect(SplitTime.count).to eq(2)
          expect(SplitTime.all.map(&:absolute_time)).to all eq(DateTime.parse(start_time))
          expect(response).to be_successful
          expect(response.message).to eq('Started 2 efforts')
        end
      end

      context 'when start_time is a valid date string without a time zone' do
        let(:start_time) { '2018-10-31 08:00:00' }

        it 'creates start split_times for each effort using the event home_time_zone' do
          response = subject.perform!
          expect(SplitTime.count).to eq(2)
          expect(SplitTime.all.map(&:absolute_time)).to all eq(start_time.in_time_zone(event.home_time_zone))
          expect(response).to be_successful
          expect(response.message).to eq('Started 2 efforts')
        end
      end

      context 'when start_time is not provided' do
        let(:start_time) { nil }

        it 'does not create any start split_times but returns an unsuccessful response with errors' do
          response = subject.perform!
          expect(SplitTime.count).to eq(0)
          expect(response).not_to be_successful
          expect(response.message).to eq('No efforts were started')
          expect(response.errors.first[:title]).to include('Invalid start time')
          expect(response.errors.first[:detail][:messages])
              .to include(/nil is not a valid start_time/)
        end
      end

      context 'when start_time is an empty string' do
        let(:start_time) { '' }

        it 'does not create any start split_times but returns an unsuccessful response with errors' do
          response = subject.perform!
          expect(SplitTime.count).to eq(0)
          expect(response).not_to be_successful
          expect(response.message).to eq('No efforts were started')
          expect(response.errors.first[:title]).to include('Invalid start time')
          expect(response.errors.first[:detail][:messages])
              .to include(/ is not a valid start_time/)
        end
      end
    end

    context 'when any provided effort cannot be started' do
      let(:effort) { create(:effort, event: event) }
      let(:event) { create(:event, event_group: event_group, course: course) }
      let(:event_group) { create(:event_group) }
      let(:course) { create(:course) }
      let(:start_split) { create(:split, :start, course: course) }

      let(:invalid_effort) { create(:effort, event: invalid_event) }
      let(:invalid_event) { create(:event, event_group: event_group, course: invalid_course) }
      let(:invalid_course) { create(:course) }

      let(:efforts) { [effort, invalid_effort] }

      before do
        allow(event).to receive(:start_split).and_return(start_split)
        allow(invalid_event).to receive(:start_split).and_return(start_split)
      end

      it 'does not create any start split_times but returns an unsuccessful response with errors' do
        response = subject.perform!
        expect(SplitTime.count).to eq(0)
        expect(response).not_to be_successful
        expect(response.message).to eq('No efforts were started')
        expect(response.errors.first[:title]).to include('SplitTime')
        expect(response.errors.first[:title]).to include('could not be saved')
        expect(response.errors.first[:detail][:messages])
            .to include(/the effort.event.course_id does not resolve with the split.course_id/)
      end
    end
  end
end
