# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::PeopleController do
  let(:person) { create(:person) }
  let(:type) { 'people' }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing person.id is provided' do
        let(:params) { {id: person} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single person' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(person.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the person does not exist' do
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
    let(:params) { {data: {type: 'people', attributes: attributes}} }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:attributes) { {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a person record' do
          expect { make_request }.to change { Person.count }.by(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: person_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {last_name: 'Updated Last Name'} }

    via_login_and_jwt do
      context 'when the person exists' do
        let(:person_id) { person.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          person.reload
          expect(person.last_name).to eq(attributes[:last_name])
        end
      end

      context 'when the person does not exist' do
        let(:person_id) { 0 }

        it 'returns an error if the person does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: person_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:person) { create(:person) }
        let(:person_id) { person.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the person record' do
          expect { make_request }.to change { Person.count }.by(-1)
        end
      end

      context 'when the record does not exist' do
        let(:person_id) { 0 }

        it 'returns an error if the person does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
