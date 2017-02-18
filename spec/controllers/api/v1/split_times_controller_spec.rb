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
      expect(response).to be_success
    end

    it 'returns data of a single split_time' do
      get :show, id: split_time
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).to eq(split_time.id)
    end

    it 'returns an error if the split_time does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response with success message' do
      post :create, split_time: {effort_id: effort.id, lap: 1, split_id: split.id,
                                 sub_split_bitkey: 1, time_from_start: 100}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/split_time created/)
      expect(parsed_response['split_time']['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a split_time record' do
      expect(SplitTime.all.count).to eq(0)
      post :create, split_time: {effort_id: effort.id, lap: 1, split_id: split.id,
                                 sub_split_bitkey: 1, time_from_start: 100}
      expect(SplitTime.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {time_from_start: 12345} }

    it 'returns a successful json response with success message' do
      put :update, id: split_time, split_time: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/split_time updated/)
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: split_time, split_time: attributes
      split_time.reload
      expect(split_time.time_from_start).to eq(attributes[:time_from_start])
    end

    it 'returns an error if the split_time does not exist' do
      put :update, id: 0, split_time: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response with success message' do
      delete :destroy, id: split_time
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/split_time destroyed/)
      expect(response).to be_success
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
      expect(response).to be_not_found
    end
  end
end