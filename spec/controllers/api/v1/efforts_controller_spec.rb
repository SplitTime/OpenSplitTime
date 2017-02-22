require 'rails_helper'

describe Api::V1::EffortsController do
  login_admin

  let(:effort) { FactoryGirl.create(:effort, event: event) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: effort
      expect(response).to be_success
    end

    it 'returns data of a single effort' do
      get :show, id: effort
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).to eq(effort.id)
    end

    it 'returns an error if the effort does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, effort: {event_id: event.id, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates an effort record' do
      expect(Effort.all.count).to eq(0)
      post :create, effort: {event_id: event.id, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}
      expect(Effort.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {last_name: 'Updated Last Name'} }

    it 'returns a successful json response' do
      put :update, id: effort, effort: attributes
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: effort, effort: attributes
      effort.reload
      expect(effort.last_name).to eq(attributes[:last_name])
    end

    it 'returns an error if the effort does not exist' do
      put :update, id: 0, effort: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: effort
      expect(response).to be_success
    end

    it 'destroys the effort record' do
      test_effort = effort
      expect(Effort.all.count).to eq(1)
      delete :destroy, id: test_effort
      expect(Effort.all.count).to eq(0)
    end

    it 'returns an error if the effort does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end