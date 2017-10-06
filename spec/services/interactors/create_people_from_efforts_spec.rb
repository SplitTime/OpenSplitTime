require 'rails_helper'
include Interactors::Errors

RSpec.describe Interactors::CreatePeopleFromEfforts do
  describe '.perform!' do
    let(:response) { Interactors::CreatePeopleFromEfforts.perform!(effort_ids) }
    let(:effort_ids) { efforts.map(&:id) }
    let(:efforts) { build_stubbed_list(:effort, 2) }
    let(:invalid_effort) { build(:effort, first_name: nil) }
    let(:errors) { [resource_error_object(invalid_effort)] }
    let(:stubbed_interactor_response) { Interactors::Response.new(errors, 'stubbed response', {saved: [], unsaved: []}) }
    let(:id_hash) { {effort_ids.first => nil, effort_ids.second => nil} }

    before do
      invalid_effort.validate
      allow(Interactors::AssignPeopleToEfforts).to receive(:perform!).and_return(stubbed_interactor_response)
    end

    it 'builds an id_hash with nil for all values and sends it to AssignPeopleToEfforts' do
      expect(Interactors::AssignPeopleToEfforts).to receive(:perform!).once.with(id_hash)
      response
    end

    context 'when errors are returned' do
      it 'returns the errors and resources provided by AssignPeopleToEfforts' do
        expect(response.errors).to eq(stubbed_interactor_response.errors)
        expect(response.resources).to eq(stubbed_interactor_response.resources)
        expect(response.message).to eq('No records were created. No records failed to create. ')
        expect(response.error_report).to eq("1 error was reported:\nEffort #{invalid_effort} could not be saved: First name can't be blank")
      end
    end
  end
end
