# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::EffortsController do
  let(:type) { 'efforts' }
  let(:effort) { efforts(:hardrock_2014_finished_first) }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing effort.id is provided' do
        let(:params) { {id: effort} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single effort' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(effort.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the effort does not exist' do
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

  describe '#with_times_row' do
    subject(:make_request) { get :with_times_row, params: params }
    let(:type) { "effort_with_times_rows" }

    via_login_and_jwt do
      context 'when an existing effort.id is provided' do
        let(:params) { {id: effort} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single effort' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(effort.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end

        it 'includes effort times row information' do
          make_request
          parsed_response = JSON.parse(response.body)
          times_row = parsed_response["included"].first
          expect(times_row["type"]).to eq("effortTimesRows")
          expect(times_row.dig("attributes", "firstName")).to eq(effort.first_name)
          expect(times_row.dig("attributes", "elapsedTimes").size).to eq(7)
        end
      end

      context 'if the effort does not exist' do
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
    let(:event) { events(:hardrock_2014) }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:params) { {data: {type: type, attributes: valid_attributes}} }
        let(:valid_attributes) { {'event_id' => event.id, 'first_name' => 'Johnny', 'last_name' => 'Appleseed', 'gender' => 'male'} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a effort record' do
          expect { make_request }.to change { Effort.count }.by(1)
        end
      end

      context 'when provided data is invalid' do
        let(:params) { {data: {type: type, attributes: invalid_attributes}} }
        let(:invalid_attributes) { {'eventId' => event.id, 'firstName' => 'Johnny'} }

        it 'returns a jsonapi error object and status code unprocessable entity' do
          make_request
          expect(response.body).to be_jsonapi_errors
          expect(response.status).to eq(422)
        end

        it 'returns the attributes of the object' do
          make_request
          parsed_response = JSON.parse(response.body)
          error_object = parsed_response['errors'].first
          expect(error_object['title']).to match(/could not be created/)
          expect(error_object['detail']['attributes']).to include(invalid_attributes)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: effort_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {last_name: 'Updated Last Name'} }

    via_login_and_jwt do
      context 'when the effort exists' do
        let(:effort_id) { effort.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          effort.reload
          expect(effort.last_name).to eq(attributes[:last_name])
        end
      end

      context 'when the effort does not exist' do
        let(:effort_id) { 0 }

        it 'returns an error if the effort does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: effort_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:effort) { create(:effort) }
        let(:effort_id) { effort.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the effort record' do
          expect { make_request }.to change { Effort.count }.by(-1)
        end
      end

      context 'when the record does not exist' do
        let(:effort_id) { 0 }

        it 'returns an error if the effort does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
