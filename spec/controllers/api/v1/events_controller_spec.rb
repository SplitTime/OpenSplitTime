require 'rails_helper'

describe Api::V1::EventsController do
  login_admin

  let(:event) { create(:event, course: course) }
  let(:course) { create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {staging_id: event.staging_id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :show, params: {staging_id: event.staging_id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('events')
    end

    it 'returns an error if the event does not exist' do
      get :show, params: {staging_id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:params) { {course_id: course.id, name: 'Test Event', start_time: '2017-03-01 06:00:00', laps_required: 1} }

    it 'returns a successful json response' do
      post :create, params: {data: {type: 'events', attributes: params }}
      expect(response.body).to be_jsonapi_response_for('events')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an event record with a staging_id' do
      expect(Event.all.count).to eq(0)
      post :create, params: {data: {type: 'events', attributes: params }}
      expect(Event.all.count).to eq(1)
      expect(Event.first.staging_id).not_to be_nil
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response' do
      put :update, params: {staging_id: event.staging_id, data: {type: 'events', attributes: attributes }}
      expect(response.body).to be_jsonapi_response_for('events')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {staging_id: event.staging_id, data: {type: 'events', attributes: attributes }}
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, params: {staging_id: 123, data: {type: 'events', attributes: attributes }}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {staging_id: event.staging_id}
      expect(response.status).to eq(200)
    end

    it 'destroys the event record' do
      test_event = event
      expect(Event.all.count).to eq(1)
      delete :destroy, params: {staging_id: test_event.staging_id}
      expect(Event.all.count).to eq(0)
    end

    it 'returns an error if the event does not exist' do
      delete :destroy, params: {staging_id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#associate_splits' do
    let(:splits_count) { 3 }
    let(:splits) { FactoryGirl.create_list(:split, splits_count, course: course) }
    let(:split_ids) { splits.map(&:id) }

    it 'returns a successful json response' do
      put :associate_splits, staging_id: event.staging_id, split_ids: split_ids
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/splits associated/)
      expect(response.status).to eq(201)
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
      expect(response.status).to eq(404)
    end
  end

  describe '#remove_splits' do
    let(:splits_count) { 3 }
    let(:removed_splits_count) { removed_split_ids.size }
    let(:splits) { FactoryGirl.create_list(:split, splits_count, course: course) }
    let(:split_ids) { splits.map(&:id) }
    let(:removed_split_ids) { split_ids.last(2) }
    before do
      event.splits << splits
    end

    it 'returns a successful json response' do
      delete :remove_splits, staging_id: event.staging_id, split_ids: removed_split_ids
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/splits removed/)
      expect(response.status).to eq(200)
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
      expect(response.status).to eq(404)
    end
  end

  describe '#spread' do
    it 'returns a successful 200 response' do
      get :spread, params: {staging_id: event.staging_id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :spread, params: {staging_id: event.staging_id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('event_spread_displays')
    end

    it 'returns an error if the event does not exist' do
      get :spread, params: {staging_id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end

    context 'when split and effort data are available' do
      before do
        FactoryGirl.reload
        create(:start_split, id: 101, course: course)
        create(:split, id: 102, course: course)
        create(:finish_split, id: 103, course: course)
        event.splits << Split.all
        create_list(:effort, 3, event: event)
        create_list(:split_times_in_out, 4, effort: Effort.first)
        create_list(:split_times_in_out_slow, 4, effort: Effort.second)
        create_list(:split_times_in_out_fast, 4, effort: Effort.third)
      end

      it 'returns split data in the expected format' do
        get :spread, params: {staging_id: event.staging_id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
            .to eq(Split.all.map(&:base_name))
      end

      it 'returns effort data in the expected format' do
        get :spread, params: {staging_id: event.staging_id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.third.last_name, Effort.first.last_name, Effort.second.last_name])
      end

      it 'sorts effort data based on the sort param' do
        get :spread, params: {staging_id: event.staging_id, sort: 'last_name'}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.first.last_name, Effort.second.last_name, Effort.third.last_name])
      end

      it 'returns time data in the expected format' do
        get :spread, params: {staging_id: event.staging_id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].first.dig('attributes', 'displayStyle')).to eq('absolute')
        expect(parsed_response['included'].first.dig('attributes', 'absoluteTimes').flatten.map { |time| time.first(19) })
            .to match(Effort.third.split_times.map { |st| st.day_and_time.to_s.first(19).gsub(' ', 'T') })
      end
    end
  end
end
