require 'rails_helper'

RSpec.describe Interactors::CreatePeopleFromEfforts do
  describe '.perform!' do
    let(:response) { Interactors::CreatePeopleFromEfforts.perform!(effort_ids) }
    let(:effort_ids) { efforts.map(&:id) }
    let(:efforts) { build_stubbed_list(:effort, 2) }
    let(:stubbed_interactor_response) { Interactors::Response.new([], 'stubbed response', {}) }
    let(:id_hash) { {effort_ids.first => nil, effort_ids.second => nil} }

    before do
      allow(Interactors::AssignPeopleToEfforts).to receive(:perform!).and_return(stubbed_interactor_response)
    end

    it 'builds an id_hash with nil for all values and sends it to AssignPeopleToEfforts' do
      expect(Interactors::AssignPeopleToEfforts).to receive(:perform!).once.with(id_hash)
      response
    end

    it 'returns the response provided by AssignPeopleToEfforts' do
      expect(response).to eq(stubbed_interactor_response)
    end
  end
end
