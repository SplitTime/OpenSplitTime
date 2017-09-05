require 'rails_helper'

describe Api::V1::LiveTimesController do
  login_admin
  before do
    event.splits << split
  end

  let(:live_time) { FactoryGirl.create(:live_time, event: event, split: split) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#index' do
    before do
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 101, absolute_time: '10:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 102, absolute_time: '11:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 103, absolute_time: '10:30:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 103, absolute_time: '16:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 101, absolute_time: '16:00:00', source: 'ost-test')
    end

    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns each live_time' do
      get :index
      expect(response.status).to eq(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].size).to eq(5)
      expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(LiveTime.all.map(&:id))
    end

    it 'sorts properly in ascending order based on a provided sort parameter' do
      expected = %w[101 101 102 103 103]
      get :index, params: {sort: 'bib_number'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end

    it 'sorts properly in descending order based on a provided sort parameter with a minus sign' do
      expected = %w[103 103 102 101 101]
      get :index, params: {sort: '-bibNumber'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end

    it 'sorts properly on multiple fields' do
      expected = %w[101 103 102 103 101]
      get :index, params: {sort: '-absolute_time,bib_number'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: live_time}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single live_time' do
      get :show, params: {id: live_time}
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(live_time.id)
    end

    it 'returns an error if the live_time does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:attributes) { {event_id: event.id, split_id: split.id, bitkey: 1, bib_number: '101',
                        absolute_time: '08:00:00', source: 'ost-test', batch: '1'} }

    it 'returns a successful json response' do
      post :create, params: {data: {type: 'live_times', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a live_time record' do
      expect(LiveTime.all.count).to eq(0)
      post :create, params: {data: {type: 'live_times', attributes: attributes}}
      expect(LiveTime.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:updated_attributes) { {bib_number: '0'} }

    it 'returns a successful json response' do
      put :update, params: {id: live_time, data: {type: 'live_times', attributes: updated_attributes}}
      expect(response.body).to be_jsonapi_response_for('live_times')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: live_time, data: {type: 'live_times', attributes: updated_attributes}}
      live_time.reload
      expect(live_time.bib_number).to eq(updated_attributes[:bib_number])
    end

    it 'returns an error if the live_time does not exist' do
      put :update, params: {id: 0, data: {type: 'live_times', attributes: updated_attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: live_time}
      expect(response.status).to eq(200)
    end

    it 'destroys the live_time record' do
      test_live_time = live_time
      expect(LiveTime.all.count).to eq(1)
      delete :destroy, params: {id: test_live_time}
      expect(LiveTime.all.count).to eq(0)
    end

    it 'returns an error if the live_time does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
