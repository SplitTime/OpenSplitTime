require 'rails_helper'

describe Api::V1::LocationsController do
  login_admin

  let(:location) { FactoryGirl.create(:location) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: location
      expect(response).to be_success
    end

    it 'returns data of a single location' do
      get :show, id: location
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(location.id)
    end

    it 'returns an error if the location does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, location: {name: 'Test Location'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a location record' do
      expect(Location.all.count).to eq(0)
      post :create, location: {name: 'Test Location'}
      expect(Location.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Location Name'} }

    it 'returns a successful json response' do
      put :update, id: location, location: attributes
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: location, location: attributes
      location.reload
      expect(location.name).to eq(attributes[:name])
    end

    it 'returns an error if the location does not exist' do
      put :update, id: 0, location: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: location
      expect(response).to be_success
    end

    it 'destroys the location record' do
      test_location = location
      expect(Location.all.count).to eq(1)
      delete :destroy, id: test_location
      expect(Location.all.count).to eq(0)
    end

    it 'returns an error if the location does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end