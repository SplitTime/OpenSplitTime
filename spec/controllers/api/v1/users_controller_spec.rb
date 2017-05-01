require 'rails_helper'

describe Api::V1::UsersController do
  login_admin

  let(:user) { FactoryGirl.create(:user) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: user}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single user' do
      get :show, params: {id: user}
      expect(response.body).to be_jsonapi_response_for('users')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(user.id)
    end

    it 'returns an error if the user does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:attributes) { {first_name: 'Test', last_name: 'User', email: 'test_user@example.com', password: 'password'} }

    it 'returns a successful json response' do
      post :create, params: {data: {type: 'users', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('users')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a user record' do
      expect(User.all.count).to eq(1)
      post :create, params: {data: {type: 'users', attributes: attributes}}
      expect(User.all.count).to eq(2)
    end
  end

  describe '#update' do
    let(:attributes) { {first_name: 'Updated First Name', pref_distance_unit: 'kilometers', pref_elevation_unit: 'meters'} }

    it 'returns a successful json response' do
      put :update, params: {id: user, data: {type: 'users', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('users')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: user, data: {type: 'users', attributes: attributes}}
      user.reload
      expect(user.first_name).to eq(attributes[:first_name])
      expect(user.pref_distance_unit).to eq(attributes[:pref_distance_unit])
      expect(user.pref_elevation_unit).to eq(attributes[:pref_elevation_unit])
    end

    it 'returns an error if the user does not exist' do
      put :update, params: {id: 0, data: {type: 'users', attributes: attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: user}
      expect(response.status).to eq(200)
    end

    it 'destroys the user record' do
      test_user = user
      expect(User.all.count).to eq(2)
      delete :destroy, params: {id: test_user}
      expect(User.all.count).to eq(1)
    end

    it 'returns an error if the user does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#current' do
    it 'returns a successful json response' do
      get :current
      expect(response.status).to eq(200)
    end

    it 'returns data of the current user' do
      get :current
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(subject.current_user.id)
    end
  end
end
