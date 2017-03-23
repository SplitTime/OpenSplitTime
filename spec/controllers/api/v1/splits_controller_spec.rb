require 'rails_helper'

describe Api::V1::SplitsController do
  login_admin

  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: split
      expect(response.status).to eq(200)
    end

    it 'returns data of a single split' do
      get :show, id: split
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(split.id)
    end

    it 'returns an error if the split does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'split', attributes: {base_name: 'Test Split', course_id: course.id,
                                                       distance_from_start: 100,
                                                       kind: 'intermediate', sub_split_bitkey: 1} }
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a split record' do
      expect(Split.all.count).to eq(0)
      post :create, data: {type: 'split', attributes: {base_name: 'Test Split', course_id: course.id,
                                                       distance_from_start: 100,
                                                       kind: 'intermediate', sub_split_bitkey: 1} }
      expect(Split.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {base_name: 'Updated Split Name', latitude: 40, longitude: -105, elevation: 2000 } }

    it 'returns a successful json response' do
      put :update, id: split, data: {type: 'split', attributes: attributes }
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: split, data: {type: 'split', attributes: attributes }
      split.reload
      expect(split.base_name).to eq(attributes[:base_name])
    end

    it 'returns an error if the split does not exist' do
      put :update, id: 0, data: {type: 'split', attributes: attributes }
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: split
      expect(response.status).to eq(200)
    end

    it 'destroys the split record' do
      test_split = split
      expect(Split.all.count).to eq(1)
      delete :destroy, id: test_split
      expect(Split.all.count).to eq(0)
    end

    it 'returns an error if the split does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
