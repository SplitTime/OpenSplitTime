require 'rails_helper'

RSpec.describe Interactors::StartEfforts do

  describe '.perform!' do
    context 'when all provided efforts can be started' do
      let(:efforts) { create_list(:effort, 2, event: event) }
      let(:event) { create(:event, course: course) }
      let(:start_split) { create(:start_split, course: course) }
      let(:course) { create(:course) }
      let(:current_user_id) { rand(1..100) }

      before do
        allow(event).to receive(:start_split).and_return(start_split)
      end

      it 'creates start split_times for each effort, assigns user_id to created_by, and returns a successful response' do
        response = Interactors::StartEfforts.perform!(efforts, current_user_id)
        expect(SplitTime.count).to eq(2)
        expect(SplitTime.all.map(&:created_by)).to eq([current_user_id] * 2)
        expect(response).to be_successful
        expect(response.message).to eq('Started 2 efforts')
      end
    end

    context 'when any provided effort cannot be started' do
      let(:effort) { create(:effort, event: event) }
      let(:event) { create(:event, course: course) }
      let(:course) { create(:course) }
      let(:start_split) { create(:start_split, course: course) }

      let(:invalid_effort) { create(:effort, event: invalid_event) }
      let(:invalid_event) { create(:event, course: invalid_course) }
      let(:invalid_course) { create(:course) }

      let(:efforts) { [effort, invalid_effort] }
      let(:current_user_id) { rand(1..100) }

      before do
        allow(event).to receive(:start_split).and_return(start_split)
        allow(invalid_event).to receive(:start_split).and_return(start_split)
      end

      it 'does not create any start split_times but returns an unsuccessful response with errors' do
        response = Interactors::StartEfforts.perform!(efforts, current_user_id)
        expect(SplitTime.count).to eq(0)
        expect(response).not_to be_successful
        expect(response.message).to eq('No efforts were started')
        expect(response.errors.first[:title]).to eq('SplitTime could not be saved')
        expect(response.errors.first[:detail][:messages])
            .to include(/the effort.event.course_id does not resolve with the split.course_id/)
      end
    end
  end
end
