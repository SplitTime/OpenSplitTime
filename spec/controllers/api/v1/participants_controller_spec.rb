require 'rails_helper'

describe Api::V1::ParticipantsController do
  login_admin

  let(:participant) { FactoryGirl.create(:participant) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: participant
      expect(response.status).to eq(200)
    end

    it 'returns data of a single participant' do
      get :show, id: participant
      expect(response.body).to be_jsonapi_response_for('participants')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(participant.id)
    end

    it 'returns an error if the participant does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'participants', attributes: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}
      expect(response.body).to be_jsonapi_response_for('participants')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a participant record' do
      expect(Participant.all.count).to eq(0)
      post :create, data: {type: 'participants', attributes: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}
      expect(Participant.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {last_name: 'Updated Last Name'} }

    it 'returns a successful json response' do
      put :update, id: participant, data: {type: 'participants', attributes: attributes}
      expect(response.body).to be_jsonapi_response_for('participants')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: participant, data: {type: 'participants', attributes: attributes}
      participant.reload
      expect(participant.last_name).to eq(attributes[:last_name])
    end

    it 'returns an error if the participant does not exist' do
      put :update, id: 0, data: {type: 'participants', attributes: attributes}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: participant
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
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
