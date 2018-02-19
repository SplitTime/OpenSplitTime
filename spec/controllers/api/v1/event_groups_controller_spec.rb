require 'rails_helper'

RSpec.describe Api::V1::EventGroupsController do
  login_admin

  let(:event_group) { create(:event_group) }

  before do
    allow(CombineEventGroupSplitAttributes)
        .to receive(:perform).and_return(['EventGroup#combined_split_attributes is stubbed for testing'])
  end

  describe '#index' do
    before do
      create(:event_group, name: 'Bravo', available_live: true)
      create(:event_group, name: 'Charlie', available_live: false)
      create(:event_group, name: 'Alpha', available_live: false)
      create(:event_group, name: 'Delta', available_live: true)
    end

    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns each event_group that the current_user is authorized to edit' do
      get :index
      expect(response.status).to eq(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].size).to eq(4)
      expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(EventGroup.all.map(&:id))
    end

    it 'sorts properly in ascending order based on a provided sort parameter' do
      expected = %w(Alpha Bravo Charlie Delta)
      get :index, params: {sort: 'name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end

    it 'sorts properly in descending order based on a provided sort parameter with a minus sign' do
      expected = %w(Delta Charlie Bravo Alpha)
      get :index, params: {sort: '-name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end

    it 'sorts properly on multiple fields' do
      expected = %w(Alpha Charlie Bravo Delta)
      get :index, params: {sort: 'available_live,name'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
    end

    context 'when a filter[:available_live] param is given' do
      let(:params) { {filter: {available_live: true}} }

      it 'returns only those event_groups that are available live' do
        get :index, params: params

        expect(response.status).to eq(200)
        expected = %w(Bravo Delta)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(2)
        expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
      end
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: event_group}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event_group' do
      get :show, params: {id: event_group}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event_group.id)
      expect(response.body).to be_jsonapi_response_for('event_groups')
    end

    it 'returns an error if the event_group does not exist' do
      get :show, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:organization) { create(:organization) }

    it 'returns a successful json response' do
      post :create, params: {data: {type: 'event_groups', attributes: {name: 'Test event_group', organization_id: organization.id}}}
      expect(response.body).to be_jsonapi_response_for('event_groups')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a event_group record' do
      expect(EventGroup.all.count).to eq(0)
      post :create, params: {data: {type: 'event_groups', attributes: {name: 'Test event_group', organization_id: organization.id}}}
      expect(EventGroup.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated EventGroup Name'} }

    it 'returns a successful json response' do
      put :update, params: {id: event_group, data: {type: 'event_groups', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('event_groups')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: event_group, data: {type: 'event_groups', attributes: attributes}}
      event_group.reload
      expect(event_group.name).to eq(attributes[:name])
    end

    it 'returns an error if the event_group does not exist' do
      put :update, params: {id: 0, data: {type: 'event_groups', attributes: attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: event_group}
      expect(response.status).to eq(200)
    end

    it 'destroys the event_group record' do
      test_event_group = event_group
      expect(EventGroup.all.count).to eq(1)
      delete :destroy, params: {id: test_event_group}
      expect(EventGroup.all.count).to eq(0)
    end

    it 'returns an error if the event_group does not exist' do
      delete :destroy, params: {id: 0}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#trigger_live_times_push' do
    let(:course) { create(:course) }
    let(:split) { create(:split, course_id: course.id) }
    let(:event) { create(:event, event_group: event_group, course: course) }
    let(:request_params) { {id: event_group.id} }
    before do
      event.splits << split
      create_list(:live_time, 3, event: event, split: split)
    end

    it 'sends a push notification that includes the count of available times' do
      allow(Pusher).to receive(:trigger)
      get :trigger_live_times_push, params: request_params
      expected_args = ["live-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 3, unmatched: 3}]
      expect(Pusher).to have_received(:trigger).with(*expected_args)
    end
  end
end
