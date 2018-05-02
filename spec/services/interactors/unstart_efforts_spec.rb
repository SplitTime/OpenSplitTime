require 'rails_helper'

RSpec.describe Interactors::UnstartEfforts do
  describe '.perform!' do
    let(:effort_1) { create(:effort, event: event, checked_in: true) }
    let(:effort_2) { create(:effort, event: event, checked_in: true) }
    let(:efforts) { [effort_1, effort_2] }

    let(:event) { create(:event, course: course) }
    let(:start_split) { create(:start_split, course: course) }
    let(:aid_1) { create(:split, course: course) }
    let(:course) { create(:course) }

    before do
      event.splits << [start_split, aid_1]
      create(:split_time, effort: effort_1, split: start_split, time_from_start: 0)
      create(:split_time, effort: effort_2, split: start_split, time_from_start: 0)
    end

    context 'when all provided efforts can be unstarted' do
      it 'removes start split_times for each effort, sets checked_in to false, and returns a successful response' do
        response = Interactors::UnstartEfforts.perform!(efforts)
        expect(SplitTime.count).to eq(0)
        expect(response).to be_successful
        expect(response.message).to eq('Changed 2 efforts to DNS')
        expect(efforts.map(&:checked_in?)).to all eq(false)
      end
    end

    context 'when any provided effort has an intermediate time' do
      before do
        create(:split_time, effort: effort_1, split: aid_1, time_from_start: 1000)
      end

      it 'does not remove any start split_times but returns an unsuccessful response with errors' do
        expect(SplitTime.count).to eq(3)
        response = Interactors::UnstartEfforts.perform!(efforts)
        expect(SplitTime.count).to eq(3)
        expect(response).not_to be_successful
        expect(response.message).to eq('No efforts were changed to DNS')
        expect(response.errors.first[:detail][:messages])
            .to include(/The effort has one or more intermediate or finish times recorded/)
      end
    end
  end
end
