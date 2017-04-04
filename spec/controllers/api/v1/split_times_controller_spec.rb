require 'rails_helper'

describe Api::V1::SplitTimesController do
  login_admin

  let(:split_time) { FactoryGirl.create(:split_time, effort: effort, split: split) }
  let(:effort) { FactoryGirl.create(:effort, event: event) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: split_time
      expect(response.status).to eq(200)
    end

    it 'returns data of a single split_time' do
      get :show, id: split_time
      expect(response.body).to be_jsonapi_response_for('split_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(split_time.id)
    end

    it 'returns an error if the split_time does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'split_times', attributes: {effort_id: effort.id, lap: 1, split_id: split.id,
                                 sub_split_bitkey: 1, time_from_start: 100} }
      expect(response.body).to be_jsonapi_response_for('split_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a split_time record' do
      expect(SplitTime.all.count).to eq(0)
      post :create, data: {type: 'split_times', attributes: {effort_id: effort.id, lap: 1, split_id: split.id,
                                                            sub_split_bitkey: 1, time_from_start: 100} }
      expect(SplitTime.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {time_from_start: 12345} }
    before do
      allow_any_instance_of(SplitTime).to receive(:set_effort_data_status)
    end

    it 'returns a successful json response' do
      put :update, id: split_time, data: {type: 'split_times', attributes: attributes}
      expect(response.body).to be_jsonapi_response_for('split_times')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: split_time, data: {type: 'split_times', attributes: attributes}
      split_time.reload
      expect(split_time.time_from_start).to eq(attributes[:time_from_start])
    end

    it 'returns an error if the split_time does not exist' do
      put :update, id: 0, data: {type: 'split_times', attributes: attributes}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: split_time
      expect(response.status).to eq(200)
    end

    it 'destroys the split_time record' do
      test_split_time = split_time
      expect(SplitTime.all.count).to eq(1)
      delete :destroy, id: test_split_time
      expect(SplitTime.all.count).to eq(0)
    end

    it 'returns an error if the split_time does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
