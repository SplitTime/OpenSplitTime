# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interactors::UnstartEfforts do
  subject { Interactors::UnstartEfforts.new(subject_efforts) }

  describe '.perform!' do
    let(:response) { subject.perform! }
    let(:effort_1) { efforts(:rufa_2017_12h_start_only) }
    let(:effort_2) { efforts(:hardrock_2016_start_only) }
    let(:subject_efforts) { [effort_1, effort_2] }

    context 'when all provided efforts can be unstarted' do
      it 'removes start split_times for each effort, sets checked_in to false, and returns a successful response' do
        expect { response }.to change { SplitTime.count }.by(-2)
        expect(response).to be_successful
        expect(response.message).to eq('Changed 2 efforts to DNS')
        expect(subject_efforts.map(&:checked_in?)).to all eq(false)
      end
    end

    context 'when any provided effort has an intermediate time' do
      let(:effort_2) { efforts(:hardrock_2016_progress_sherman) }

      it 'does not remove any start split_times but returns an unsuccessful response with errors' do
        expect { response }.not_to change { SplitTime.count }
        expect(response).not_to be_successful
        expect(response.message).to eq('No efforts were changed to DNS')
        expect(response.errors.first[:detail][:messages])
            .to include(/The effort has one or more intermediate or finish times recorded/)
      end
    end
  end
end
