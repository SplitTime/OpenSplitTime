require 'rails_helper'

describe Api::V1::EventsController do
  login_admin

  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, staging_id: event.staging_id
      expect(response).to be_success
    end

    it 'returns data of a single event' do
      get :show, staging_id: event.staging_id
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
    end

    it 'returns an error if the event does not exist' do
      get :show, staging_id: 123
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    let(:params) { {course_id: course.id, name: 'Test Event', start_time: '2017-03-01 06:00:00', laps_required: 1} }

    it 'returns a successful json response with success message' do
      post :create, event: params
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event created/)
      expect(parsed_response['event']['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates an event record with a staging_id' do
      expect(Event.all.count).to eq(0)
      post :create, event: params
      expect(Event.all.count).to eq(1)
      expect(Event.first.staging_id).not_to be_nil
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response with success message' do
      put :update, staging_id: event.staging_id, event: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event updated/)
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, staging_id: event.staging_id, event: attributes
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, staging_id: 123, event: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response with success message' do
      delete :destroy, staging_id: event.staging_id
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event destroyed/)
      expect(response).to be_success
    end

    it 'destroys the event record' do
      test_event = event
      expect(Event.all.count).to eq(1)
      delete :destroy, staging_id: test_event.staging_id
      expect(Event.all.count).to eq(0)
    end

    it 'returns an error if the event does not exist' do
      delete :destroy, staging_id: 123
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#associate_splits' do
    let(:splits_count) { 3 }
    let(:splits) { FactoryGirl.create_list(:split, splits_count, course: course) }
    let(:split_ids) { splits.map(&:id) }

    it 'returns a successful json response with success message' do
      put :associate_splits, staging_id: event.staging_id, split_ids: split_ids
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/splits associated/)
      expect(response).to be_success
    end

    it 'associates the specified splits with the event' do
      expect(event.splits.ids).to eq([])
      put :associate_splits, staging_id: event.staging_id, split_ids: split_ids
      expect(event.splits.size).to eq(splits_count)
      expect(event.splits.ids).to eq(split_ids)
    end

    it 'does not create a second association for splits already associated' do
      put :associate_splits, staging_id: event.staging_id, split_ids: split_ids
      expect(event.splits.size).to eq(splits_count)
      put :associate_splits, staging_id: event.staging_id, split_ids: split_ids
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/already associated/)
      expect(event.splits.size).to eq(splits_count)
    end

    it 'returns an error if the splits do not exist' do
      put :associate_splits, staging_id: event.staging_id, split_ids: [0]
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#remove_split' do
    let(:splits_count) { 3 }
    let(:removed_splits_count) { removed_split_ids.size }
    let(:splits) { FactoryGirl.create_list(:split, splits_count, course: course) }
    let(:split_ids) { splits.map(&:id) }
    let(:removed_split_ids) { split_ids.last(2) }
    before do
      event.splits << splits
    end

    it 'returns a successful json response with success message' do
      delete :remove_splits, staging_id: event.staging_id, split_ids: removed_split_ids
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/splits removed/)
      expect(response).to be_success
    end

    it 'removes the specified split from the event' do
      expect(event.splits.ids).to eq(split_ids)
      expect(event.splits.size).to eq(splits_count)
      delete :remove_splits, staging_id: event.staging_id, split_ids: removed_split_ids
      expect(event.splits.size).to eq(splits_count - removed_splits_count)
      expect(event.splits.ids).to eq(split_ids - removed_split_ids)
    end

    it 'returns an error if the split does not exist' do
      delete :remove_splits, staging_id: event.staging_id, split_ids: [0]
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end