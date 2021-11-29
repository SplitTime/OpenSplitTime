# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::SplitTimesController do
  include BitkeyDefinitions

  let(:type) { 'split_times' }
  let(:split_time) { create(:split_time, effort: effort, split: split, bitkey: bitkey) }
  let(:effort) { efforts(:hardrock_2016_progress_sherman) }
  let(:split) { splits(:hardrock_cw_cunningham) }
  let(:bitkey) { in_bitkey }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing split_time.id is provided' do
        let(:params) { {id: split_time} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single split_time' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(split_time.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the split_time does not exist' do
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
    let(:params) { {data: {type: 'split_times', attributes: attributes}} }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:attributes) { {effort_id: effort.id, lap: 1, split_id: split.id, sub_split_bitkey: 1, absolute_time: '2018-10-31 06:00:00'} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a split_time record' do
          expect { make_request }.to change { SplitTime.count }.by(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: split_time_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {absolute_time: '2018-10-31 01:23:45'} }

    via_login_and_jwt do
      context 'when the split_time exists' do
        let(:split_time_id) { split_time.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          split_time.reload
          expect(split_time.absolute_time).to eq(attributes[:absolute_time])
        end
      end

      context 'when the split_time does not exist' do
        let(:split_time_id) { 0 }

        it 'returns an error if the split_time does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: split_time_id} }
    let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: in_bitkey) }

    via_login_and_jwt do
      context 'when the record exists' do
        let(:split_time_id) { split_time.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the split_time record' do
          expect { make_request }.to change { SplitTime.count }.by(-1)
        end
      end

      context 'when the record does not exist' do
        let(:split_time_id) { 0 }

        it 'returns an error if the split_time does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
