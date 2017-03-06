require 'rails_helper'

describe Api::V1::ParticipantsController do
  login_admin

  let(:participant) { FactoryGirl.create(:participant) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: participant
      expect(response).to be_success
    end

    it 'returns data of a single participant' do
      get :show, id: participant
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(participant.id)
    end

    it 'returns an error if the participant does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response with success message' do
      post :create, participant: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/participant created/)
      expect(parsed_response['participant']['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a participant record' do
      expect(Participant.all.count).to eq(0)
      post :create, participant: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}
      expect(Participant.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {last_name: 'Updated Last Name'} }

    it 'returns a successful json response with success message' do
      put :update, id: participant, participant: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/participant updated/)
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: participant, participant: attributes
      participant.reload
      expect(participant.last_name).to eq(attributes[:last_name])
    end

    it 'returns an error if the participant does not exist' do
      put :update, id: 0, participant: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response with success message' do
      delete :destroy, id: participant
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/participant destroyed/)
      expect(response).to be_success
    end

    it 'destroys the participant record' do
      test_participant = participant
      expect(Participant.all.count).to eq(1)
      delete :destroy, id: test_participant
      expect(Participant.all.count).to eq(0)
    end

    it 'returns an error if the participant does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end