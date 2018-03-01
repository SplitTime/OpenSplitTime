require 'rails_helper'

RSpec.describe Api::V1::EventGroupsController do
  let(:event_group) { create(:event_group) }
  let(:type) { 'event_groups' }

  before do
    allow(CombineEventGroupSplitAttributes)
        .to receive(:perform).and_return(['EventGroup#combined_split_attributes is stubbed for testing'])
  end


  describe '#index' do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

    before do
      create(:event_group, name: 'Bravo', available_live: true)
      create(:event_group, name: 'Charlie', available_live: false)
      create(:event_group, name: 'Alpha', available_live: false)
      create(:event_group, name: 'Delta', available_live: true)
    end

    via_login_and_jwt do
      it 'returns a successful 200 response' do
        make_request
        expect(response.status).to eq(200)
      end

      it 'returns each event_group' do
        make_request
        expect(response.status).to eq(200)
        expect(EventGroup.count).to eq(4)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(4)
        expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(EventGroup.all.map(&:id))
      end

      context 'when a sort parameter is provided' do
        let(:params) { {sort: 'name'} }

        it 'sorts properly in ascending order based on the parameter' do
          make_request
          expected = %w(Alpha Bravo Charlie Delta)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end

      context 'when a negative sort parameter is provided' do
        let(:params) { {sort: '-name'} }

        it 'sorts properly in descending order based on the parameter' do
          make_request
          expected = %w(Delta Charlie Bravo Alpha)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end

      context 'when multiple sort parameters are provided' do
        let(:params) { {sort: 'available_live,name'} }

        it 'sorts properly on multiple fields' do
          make_request
          expected = %w(Alpha Charlie Bravo Delta)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end

      context 'when a filter[:available_live] param is given' do
        let(:params) { {filter: {available_live: true}} }

        it 'returns only those event_groups that are available live' do
          get :index, params: params

          expect(response.status).to eq(200)
          expected = %w(Bravo Delta)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(2)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to match_array(expected)
        end
      end
    end
  end

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing event_group.id is provided' do
        let(:params) { {id: event_group} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single event_group' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(event_group.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the event_group does not exist' do
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

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:params) { {data: {type: type, attributes: {name: 'Test Event Group'}}} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates an event_group record' do
          expect(EventGroup.all.count).to eq(0)
          make_request
          expect(EventGroup.all.count).to eq(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: event_group_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {name: 'Updated EventGroup Name'} }

    via_login_and_jwt do
      context 'when the event_group exists' do
        let(:event_group_id) { event_group.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          event_group.reload
          expect(event_group.name).to eq(attributes[:name])
        end
      end

      context 'when the event_group does not exist' do
        let(:event_group_id) { 0 }

        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: event_group_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:event_group) { create(:event_group) }
        let(:event_group_id) { event_group.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the event_group record' do
          expect(EventGroup.all.count).to eq(1)
          make_request
          expect(EventGroup.all.count).to eq(0)
        end
      end

      context 'when the record does not exist' do
        let(:event_group_id) { 0 }

        it 'returns an error if the event_group does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#trigger_live_times_push' do
    subject(:make_request) { get :trigger_live_times_push, params: request_params }
    let(:course) { create(:course) }
    let(:split) { create(:split, course_id: course.id) }
    let(:event) { create(:event, event_group: event_group, course: course) }
    let(:request_params) { {id: event_group.id} }
    before do
      event.splits << split
      create_list(:live_time, 3, event: event, split: split)
    end

    via_login_and_jwt do
      it 'sends a push notification that includes the count of available times' do
        allow(Pusher).to receive(:trigger)
        make_request
        expected_args = ["live-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 3, unmatched: 3}]
        expect(Pusher).to have_received(:trigger).with(*expected_args)
      end
    end
  end
end
