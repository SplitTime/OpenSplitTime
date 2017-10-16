require 'rails_helper'

RSpec.describe Api::V1::EffortsController do
  login_admin

  let(:effort) { FactoryGirl.create(:effort, event: event) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: effort}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single effort' do
      get :show, params: {id: effort}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(effort.id)
      expect(response.body).to be_jsonapi_response_for('efforts')
    end

    it 'returns an error if the effort does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    context 'when provided with valid attributes' do
      let(:valid_attributes) { {'event_id' => event.id, 'first_name' => 'Johnny', 'last_name' => 'Appleseed', 'gender' => 'male'} }

      it 'returns a successful json response' do
        post :create, params: {data: {type: 'efforts', attributes: valid_attributes}}
        expect(response.body).to be_jsonapi_response_for('efforts')
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data']['id']).not_to be_nil
        expect(response.status).to eq(201)
      end

      it 'creates an effort record' do
        expect(Effort.all.count).to eq(0)
        post :create, params: {data: {type: 'efforts', attributes: valid_attributes}}
        expect(Effort.all.count).to eq(1)
      end
    end

    context 'when provided with invalid attributes' do
      let(:invalid_attributes) { {'eventId' => event.id, 'firstName' => 'Johnny'} }

      it 'returns a jsonapi error object and status code unprocessable entity' do
        post :create, params: {data: {type: 'efforts', attributes: invalid_attributes}}
        expect(response.body).to be_jsonapi_errors
        expect(response.status).to eq(422)
      end

      it 'returns the attributes of the object' do
        post :create, params: {data: {type: 'efforts', attributes: invalid_attributes}}
        parsed_response = JSON.parse(response.body)
        error_object = parsed_response['errors'].first
        expect(error_object['title']).to match(/could not be created/)
        expect(error_object['detail']['attributes']).to include(invalid_attributes)
      end
    end
  end

  describe '#update' do
    let(:attributes) { {last_name: 'Updated Last Name'} }

    it 'returns a successful json response' do
      put :update, params: {id: effort, data: {type: 'efforts', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('efforts')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: effort, data: {type: 'efforts', attributes: attributes}}
      effort.reload
      expect(effort.last_name).to eq(attributes[:last_name])
    end

    it 'returns an error if the effort does not exist' do
      put :update, params: {id: 0, data: {type: 'efforts', attributes: attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: effort}
      expect(response.status).to eq(200)
    end

    it 'destroys the effort record' do
      test_effort = effort
      expect(Effort.all.count).to eq(1)
      delete :destroy, params: {id: test_effort}
      expect(Effort.all.count).to eq(0)
    end

    it 'returns an error if the effort does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
