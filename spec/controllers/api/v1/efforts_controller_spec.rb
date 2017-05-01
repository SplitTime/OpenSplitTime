require 'rails_helper'

describe Api::V1::EffortsController do
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
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, params: {data: {type: 'efforts', attributes: {event_id: event.id, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}}
      expect(response.body).to be_jsonapi_response_for('efforts')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an effort record' do
      expect(Effort.all.count).to eq(0)
      post :create, params: {data: {type: 'efforts', attributes: {event_id: event.id, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male'}}}
      expect(Effort.all.count).to eq(1)
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
      expect(parsed_response['message']).to match(/not found/)
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
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
