require 'rails_helper'

RSpec.describe Api::V1::PeopleController do
  login_admin

  let(:person) { FactoryGirl.create(:person) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: person}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single person' do
      get :show, params: {id: person}
      expect(response.body).to be_jsonapi_response_for('people')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(person.id)
    end

    it 'returns an error if the person does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, params: {data: {type: 'people', attributes: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}}
      expect(response.body).to be_jsonapi_response_for('people')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a person record' do
      expect(Person.all.count).to eq(0)
      post :create, params: {data: {type: 'people', attributes: {first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}}
      expect(Person.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {last_name: 'Updated Last Name'} }

    it 'returns a successful json response' do
      put :update, params: {id: person, data: {type: 'people', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('people')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: person, data: {type: 'people', attributes: attributes}}
      person.reload
      expect(person.last_name).to eq(attributes[:last_name])
    end

    it 'returns an error if the person does not exist' do
      put :update, params: {id: 0, data: {type: 'people', attributes: attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: person}
      expect(response).to be_success
    end

    it 'destroys the person record' do
      test_person = person
      expect(Person.all.count).to eq(1)
      delete :destroy, params: {id: test_person}
      expect(Person.all.count).to eq(0)
    end

    it 'returns an error if the person does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
