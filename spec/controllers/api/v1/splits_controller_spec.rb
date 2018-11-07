# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::SplitsController do
  let(:type) { 'splits' }
  let(:split) { create(:split, course: course) }
  let(:course) { create(:course) }

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing split.id is provided' do
        let(:params) { {id: split} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single split' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(split.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the split does not exist' do
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
    let(:params) { {data: {type: 'splits', attributes: attributes}} }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:attributes) { {base_name: 'Test Split', course_id: course.id, distance_from_start: 100,
                            kind: 'intermediate', sub_split_bitkey: 1} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a split record' do
          expect { make_request }.to change { Split.count }.by(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: split_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {base_name: 'Updated Split Name', latitude: 40, longitude: -105, elevation: 2000} }

    via_login_and_jwt do
      context 'when the split exists' do
        let(:split_id) { split.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          split.reload
          %i(base_name latitude longitude elevation).each do |attr|
            expect(split.send(attr)).to eq(attributes[attr])
          end
        end
      end

      context 'when the split does not exist' do
        let(:split_id) { 0 }

        it 'returns an error if the split does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: split_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:split) { create(:split) }
        let(:split_id) { split.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the split record' do
          expect { make_request }.to change { Split.count }.by(-1)
        end
      end

      context 'when any split_times are associated with the split' do
        let(:split_id) { split.id }

        it 'returns an error message' do
          event = create(:event, course: course)
          effort = create(:effort, event: event)
          create(:split_time, split: split, effort: effort)
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors'].first['detail']['messages']).to include(/Split has 1 associated split times/)
          expect(response.status).to eq(422)
        end
      end

      context 'when the record does not exist' do
        let(:split_id) { 0 }

        it 'returns an error if the split does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
