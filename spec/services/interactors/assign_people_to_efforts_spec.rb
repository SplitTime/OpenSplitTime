require 'rails_helper'

RSpec.describe Interactors::AssignPeopleToEfforts do
  describe '.perform' do
    let(:response) { Interactors::AssignPeopleToEfforts.perform(id_hash) }
    let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s, efforts.second.id.to_s => people.second.id.to_s} }
    let(:efforts) { build_stubbed_list(:effort, 2) }
    let(:people) { build_stubbed_list(:person, 2) }

    before do
      allow(Effort).to receive(:where).and_return(efforts)
      allow(Person).to receive(:where).and_return(people)
    end

    context 'in all cases' do
      let(:stubbed_interactor_response) { Interactors::Response.new([], 'stubbed response', {}) }
      before do
        allow(Interactors::AssignPersonToEffort).to receive(:perform).and_return(stubbed_interactor_response)
      end

      it 'sends a message to AssignPersonToEffort for each id_hash effort_id/person_id pair' do
        expect(Interactors::AssignPersonToEffort).to receive(:perform).with(people.first, efforts.first)
        expect(Interactors::AssignPersonToEffort).to receive(:perform).with(people.second, efforts.second)
        response
      end
    end

    context 'when people are successfully assigned to efforts' do
      before do
        efforts.each { |effort| allow(effort).to receive(:valid?).and_return true }
        people.each { |person| allow(person).to receive(:valid?).and_return true }
      end

      it 'returns a successful response with a descriptive message' do
        expect(response).to be_successful
        expect(response.message).to eq('2 pairs were provided. 4 modified resources are valid. 0 modified resources are invalid.')
      end

      it 'returns all resources within the resources[:valid] key' do
        expect(response.resources[:valid].count).to eq(4)
        expect(response.resources[:valid]).to include(efforts.first)
        expect(response.resources[:valid]).to include(efforts.second)
        expect(response.resources[:valid]).to include(people.first)
        expect(response.resources[:valid]).to include(people.second)
      end
    end

    context 'when any person is not successfully assigned to an effort' do
      before do
        allow(efforts.first).to receive(:valid?).and_return true
        allow(efforts.second).to receive(:valid?).and_return false
        allow(people.first).to receive(:valid?).and_return true
        allow(people.second).to receive(:valid?).and_return false
      end

      it 'returns an unsuccessful response with descriptive message and descriptive errors' do
        expect(response).not_to be_successful
        expect(response.message).to eq('2 pairs were provided. 2 modified resources are valid. 2 modified resources are invalid.')
        expect(response.errors).to be_present
        expect(response.errors.first[:title]).to eq('Person could not be saved')
      end

      it 'returns the saved effort and person within the resources[:valid] key' do
        expect(response.resources[:valid].count).to eq(2)
        expect(response.resources[:valid]).to include(efforts.first)
        expect(response.resources[:valid]).to include(people.first)
      end
    end
  end
end
