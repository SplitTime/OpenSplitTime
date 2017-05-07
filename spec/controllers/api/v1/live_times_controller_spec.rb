require 'rails_helper'

describe Api::V1::LiveTimesController do
  login_admin

  let(:live_time) { FactoryGirl.create(:live_time, event: event, split: split) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: live_time
      expect(response.status).to eq(200)
    end

    it 'returns data of a single live_time' do
      get :show, id: live_time
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(live_time.id)
    end

    it 'returns an error if the live_time does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'live_times', attributes: {event_id: event.id, lap: 1, split_id: split.id,
                                 split_extension: 'in', bib_number: '101', absolute_time: '08:00:00'} }
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a live_time record' do
      expect(LiveTime.all.count).to eq(0)
      post :create, data: {type: 'live_times', attributes: {event_id: event.id, lap: 1, split_id: split.id,
                                                            split_extension: 'in', bib_number: '101', absolute_time: '08:00:00'} }
      expect(LiveTime.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {bib_number: 0} }

    it 'returns a successful json response' do
      put :update, id: live_time, data: {type: 'live_times', attributes: attributes}
      expect(response.body).to be_jsonapi_response_for('live_times')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: live_time, data: {type: 'live_times', attributes: attributes}
      live_time.reload
      expect(live_time.bib_number).to eq(attributes[:bib_number])
    end

    it 'returns an error if the live_time does not exist' do
      put :update, id: 0, data: {type: 'live_times', attributes: attributes}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: live_time
      expect(response.status).to eq(200)
    end

    it 'destroys the live_time record' do
      test_live_time = live_time
      expect(LiveTime.all.count).to eq(1)
      delete :destroy, id: test_live_time
      expect(LiveTime.all.count).to eq(0)
    end

    it 'returns an error if the live_time does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
