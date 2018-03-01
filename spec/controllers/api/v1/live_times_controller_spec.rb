require 'rails_helper'

RSpec.describe Api::V1::LiveTimesController do
  before { event.splits << split }
  let(:type) { 'live_times' }

  let(:live_time) { create(:live_time, event: event, split: split) }
  let(:event) { create(:event, course: course) }
  let(:split) { create(:split, course: course) }
  let(:course) { create(:course) }

  describe '#index' do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

    before do
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: '101', absolute_time: '10:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: '102', absolute_time: '11:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: '103', absolute_time: '10:30:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: '103', absolute_time: '16:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: '101', absolute_time: '16:00:00', source: 'ost-test')
    end

    via_login_and_jwt do
      it 'returns a successful 200 response' do
        make_request
        expect(response.status).to eq(200)
      end

      it 'returns each live_time' do
        make_request
        expect(response.status).to eq(200)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(5)
        expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(LiveTime.all.map(&:id))
      end

      context 'when provided with a sort parameter' do
        let(:params) { {sort: 'bib_number'} }

        it 'sorts properly in ascending order' do
          expected = %w[101 101 102 103 103]
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
        end
      end

      context 'when provided with a sort parameter' do
        let(:params) { {sort: '-bib_number'} }

        it 'sorts properly in descending order' do
          expected = %w[103 103 102 101 101]
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
        end
      end

      context 'when provided with multiple sort parameters' do
        let(:params) { {sort: '-absolute_time,bib_number'} }

        it 'sorts properly on multiple fields' do
          expected = %w[101 103 102 103 101]
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
        end
      end
    end
  end

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when the provided live_time exists' do
        let(:params) { {id: live_time.id} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single live_time' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(live_time.id)
        end
      end

      context 'when the live_time does not exist' do
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
    let(:params) { {data: {type: type, attributes: attributes}} }
    let(:attributes) { {event_id: event.id, split_id: split.id, bitkey: 1, bib_number: '101',
                        absolute_time: '08:00:00', source: 'ost-test', batch: '1'} }

    via_login_and_jwt do
      it 'returns a successful json response' do
        make_request
        expect(response.body).to be_jsonapi_response_for(type)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data']['id']).not_to be_nil
        expect(response.status).to eq(201)
      end

      it 'creates a live_time record' do
        expect(LiveTime.all.count).to eq(0)
        make_request
        expect(LiveTime.all.count).to eq(1)
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: live_time_id, data: {type: type, attributes: updated_attributes}} }
    let(:live_time_id) { live_time.id }
    let(:updated_attributes) { {bib_number: '0'} }

    via_login_and_jwt do
      context 'when the live_time exists' do
        let(:live_time_id) { live_time.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          live_time.reload
          expect(live_time.bib_number).to eq(updated_attributes[:bib_number])
        end
      end

      context 'when the live_time does not exist' do
        let(:live_time_id) { 0 }

        it 'returns an error if the live_time does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: live_time_id} }

    via_login_and_jwt do
      context 'when the live_time exists' do
        let(:live_time_id) { live_time.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the live_time record' do
          live_time
          expect(LiveTime.all.count).to eq(1)
          make_request
          expect(LiveTime.all.count).to eq(0)
        end
      end

      context 'when the live_time does not exist' do
        let(:live_time_id) { 0 }
        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
