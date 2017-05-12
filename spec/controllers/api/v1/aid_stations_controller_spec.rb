require 'rails_helper'

describe Api::V1::AidStationsController do
  login_admin

  let(:course) { create(:course) }
  let(:split) { create(:split, course: course) }
  let(:event) { create(:event, course: course) }
  let(:aid_station) { AidStation.create!(split: split, event: event) }
  
  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: aid_station
      expect(response.status).to eq(200)
    end

    it 'returns data of a single aid_station' do
      get :show, id: aid_station
      expect(response.body).to be_jsonapi_response_for('aid_stations')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(aid_station.id)
    end

    it 'returns an error if the aid_station does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'aid_stations', attributes: {split_id: split.id, event_id: event.id} }
      expect(response.body).to be_jsonapi_response_for('aid_stations')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a aid_station record' do
      expect(AidStation.all.count).to eq(0)
      post :create, data: {type: 'aid_stations', attributes: {split_id: split.id, event_id: event.id} }
      expect(AidStation.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {captain_name: 'Walt Whitman', open_time: '2017-07-01 08:00:00'} }

    it 'returns a successful json response' do
      put :update, id: aid_station, data: {type: 'aid_stations', attributes: attributes }
      expect(response.body).to be_jsonapi_response_for('aid_stations')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: aid_station, data: {type: 'aid_stations', attributes: attributes }
      aid_station.reload
      expect(aid_station.captain_name).to eq(attributes[:captain_name])
      expect(aid_station.open_time).to be_a(ActiveSupport::TimeWithZone)
    end

    it 'returns an error if the aid_station does not exist' do
      put :update, id: 0, data: {type: 'aid_stations', attributes: attributes }
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: aid_station
      expect(response.status).to eq(200)
    end

    it 'destroys the aid_station record' do
      test_aid_station = aid_station
      expect(AidStation.all.count).to eq(1)
      delete :destroy, id: test_aid_station
      expect(AidStation.all.count).to eq(0)
    end

    it 'returns an error if the aid_station does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
