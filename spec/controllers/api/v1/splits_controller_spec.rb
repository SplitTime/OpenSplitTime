require 'rails_helper'

describe Api::V1::SplitsController do
  login_admin

  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: split
      expect(response).to be_success
    end

    it 'returns data of a single split' do
      get :show, id: split
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).to eq(split.id)
    end

    it 'returns an error if the split does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, split: {base_name: 'Test Split', course_id: course.id, distance_from_start: 100,
                            kind: 'intermediate', sub_split_bitkey: 1}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a split record' do
      expect(Split.all.count).to eq(0)
      post :create, split: {base_name: 'Test Split', course_id: course.id, distance_from_start: 100,
                            kind: 'intermediate', sub_split_bitkey: 1}
      expect(Split.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {base_name: 'Updated Split Name', latitude: 40, longitude: -105, elevation: 2000 } }

    it 'returns a successful json response' do
      put :update, id: split, split: attributes
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: split, split: attributes
      split.reload
      expect(split.base_name).to eq(attributes[:base_name])
    end

    it 'returns an error if the split does not exist' do
      put :update, id: 0, split: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: split
      expect(response).to be_success
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
      expect(response).to be_not_found
    end
  end
end