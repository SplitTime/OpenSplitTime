# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::AidStationsController do
  let(:course) { create(:course) }
  let(:split) { create(:split, course: course) }
  let(:event) { create(:event, course: course) }
  let(:aid_station) { create(:aid_station, split: split, event: event) }
  let(:type) { 'aid_stations' }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing aid_station.id is provided' do
        let(:params) { {id: aid_station} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single aid_station' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(aid_station.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the aid_station does not exist' do
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

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:params) { {data: {type: type, attributes: {split_id: split.id, event_id: event.id}}} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a aid_station record' do
          expect { make_request }.to change { AidStation.count }.by(1)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: aid_station_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:aid_station) { create(:aid_station, event: event, split: split) }
        let(:aid_station_id) { aid_station.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the aid_station record' do
          expect { make_request }.to change { AidStation.count }.by(-1)
        end
      end

      context 'when the record does not exist' do
        let(:aid_station_id) { 0 }

        it 'returns an error if the aid_station does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
