require 'rails_helper'

RSpec.describe Interactors::AssignPeopleToEfforts do
  describe '.perform!' do
    let(:response) { Interactors::AssignPeopleToEfforts.perform!(id_hash) }
    let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s,
                     efforts.second.id.to_s => people.second.id.to_s} }
    let(:people) { create_list(:person, 2) }
    let(:efforts) { create_list(:effort, 2, event: event) }
    let(:event) { create(:event) }

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
      it 'returns a successful response with a descriptive message' do
        expect(response).to be_successful
        expect(response.message).to eq('Reconciled 2 efforts. ')
      end

      it 'returns all resources within the resources[:saved] key' do
        expect(response.resources[:saved].count).to eq(2)
        expect(response.resources[:saved]).to include({effort: efforts.first, person: people.first})
        expect(response.resources[:saved]).to include({effort: efforts.second, person: people.second})
      end
    end

    context 'when any person is not successfully assigned to an effort' do
      let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s,
                       efforts.second.id.to_s => people.first.id.to_s} }

      it 'returns an unsuccessful response with descriptive message and descriptive errors' do
        expect(response).not_to be_successful
        expect(response.message).to include('Reconciled')
        expect(response.message).to include('Could not reconcile')
        expect(response.errors).to be_present
        expect(response.errors.first[:title]).to eq("Effort #{efforts.second} could not be saved")
      end

      it 'returns saved and unsaved effort/person pairs within the relevant resources key' do
        expect(response.resources[:saved].size).to eq(1)
        expect(response.resources[:saved]).to include({effort: efforts.first, person: people.first})
        expect(response.resources[:unsaved].size).to eq(1)
        expect(response.resources[:unsaved]).to include({effort: efforts.second, person: people.first})
      end
    end

    context 'when any person is not successfully assigned to an effort and more than three pairs are provided' do
      let(:efforts) { create_list(:effort, 3, event: event) }
      let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s,
                       efforts.second.id.to_s => people.first.id.to_s,
                       efforts.third.id.to_s => people.second.id.to_s} }

      it 'returns a descriptive message with the number of pairs' do
        expect(response).not_to be_successful
        expect(response.message).to include('Attempted to reconcile 3 efforts.')
        expect(response.message).to include('Reconciled')
        expect(response.message).to include('Could not reconcile')
      end
    end

    context 'when any person_id is nil' do
      let(:id_hash) { {efforts.first.id.to_s => nil,
                       efforts.second.id.to_s => nil} }

      it 'creates new Person records and assigns them to the provided efforts' do
        expect(Person.count).to eq(0)
        response
        expect(Person.count).to eq(2)
        response.resources[:saved].each do |person_effort_hash|
          effort = person_effort_hash[:effort]
          person = person_effort_hash[:person]
          expect(effort.person_id).to eq(person.id)
          expect(effort.first_name).to eq(person.first_name)
          expect(effort.last_name).to eq(person.last_name)
          expect(effort.gender).to eq(person.gender)
        end
      end
    end

    context 'when any effort is not found' do
      let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s,
                       '0' => people.second.id.to_s} }

      it 'raises an error' do
        expect { response }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when any person is not found' do
      let(:id_hash) { {efforts.first.id.to_s => people.first.id.to_s,
                       efforts.second.id.to_s => '0'} }

      it 'raises an error' do
        expect { response }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
