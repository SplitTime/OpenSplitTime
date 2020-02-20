require 'rails_helper'

RSpec.describe Persist::SaveRecords do
  subject { described_class.new(model, resources) }
  let(:model) { User }

  describe '#initialize' do
    include_examples 'initializes with model and resources'
  end

  describe '#perform!' do
    let(:resources) { build_list(:user, 3) }

    context 'when all records are valid' do
      it 'saves all records and returns a successful response' do
        response = subject.perform!
        expect(response).to be_successful
        expect(resources).to all be_persisted
      end
    end

    context 'when an error occurs' do
      before { resources.first.assign_attributes(email: nil) }

      it 'does not save any resource, and returns errors and a descriptive message' do
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:title]).to match(/could not be updated/)
        expect(response.message).to match(/could not be saved/)
      end
    end
  end
end
