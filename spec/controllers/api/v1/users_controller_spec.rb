# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UsersController do
  let(:user) { create(:user) }
  let(:type) { 'users' }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing user.id is provided' do
        let(:params) { {id: user} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single user' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(user.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the user does not exist' do
        let(:params) { {id: 0} }

        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#create' do
    subject(:make_request) { post :create, params: params }
    let(:params) { {data: {type: 'users', attributes: attributes}} }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:attributes) { {first_name: 'Test', last_name: 'User', email: 'test_user@example.com', password: 'password'} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a user record' do
          expect { make_request }.to change { User.count }.by(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: user_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {last_name: 'Updated Last Name'} }

    via_login_and_jwt do
      context 'when the user exists' do
        let(:user_id) { user.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          user.reload
          expect(user.last_name).to eq(attributes[:last_name])
        end
      end

      context 'when the user does not exist' do
        let(:user_id) { 0 }

        it 'returns an error if the user does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: user_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:user) { create(:user) }
        let(:user_id) { user.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the user record' do
          expect { make_request }.to change { User.count }.by(-1)
        end
      end

      context 'when the record does not exist' do
        let(:user_id) { 0 }

        it 'returns an error if the user does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#current' do
    let(:make_request) { get :current }

    via_login_and_jwt do
      it 'returns a successful json response' do
        make_request
        expect(response.status).to eq(200)
      end

      it 'returns data of the current user' do
        make_request
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data']['id'].to_i).to eq(subject.current_user.id)
      end
    end
  end
end
