require 'rails_helper'

describe Api::V1::EventsController do
  login_admin

  let(:event) { create(:event, course: course) }
  let(:course) { create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, staging_id: event.staging_id
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :show, staging_id: event.staging_id
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('events')
    end

    it 'returns an error if the event does not exist' do
      get :show, staging_id: 123
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:params) { {course_id: course.id, name: 'Test Event', start_time: '2017-03-01 06:00:00', laps_required: 1} }

    it 'returns a successful json response' do
      post :create, data: {type: 'events', attributes: params}
      expect(response.body).to be_jsonapi_response_for('events')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an event record with a staging_id' do
      expect(Event.all.count).to eq(0)
      post :create, data: {type: 'events', attributes: params}
      expect(Event.all.count).to eq(1)
      expect(Event.first.staging_id).not_to be_nil
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response' do
      put :update, staging_id: event.staging_id, data: {type: 'events', attributes: attributes}
      expect(response.body).to be_jsonapi_response_for('events')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, staging_id: event.staging_id, data: {type: 'events', attributes: attributes}
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, staging_id: 123, data: {type: 'events', attributes: attributes}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, staging_id: event.staging_id
      expect(response.status).to eq(200)
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
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#spread' do
    it 'returns a successful 200 response' do
      get :spread, staging_id: event.staging_id
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :spread, staging_id: event.staging_id
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('event_spread_displays')
    end

    it 'returns an error if the event does not exist' do
      get :spread, staging_id: 123
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
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
        get :spread, staging_id: event.staging_id
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
            .to eq(Split.all.map(&:base_name))
      end

      it 'returns effort data in the expected format' do
        get :spread, staging_id: event.staging_id
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.third.last_name, Effort.first.last_name, Effort.second.last_name])
      end

      it 'sorts effort data based on the sort param' do
        get :spread, staging_id: event.staging_id, sort: 'last_name'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.first.last_name, Effort.second.last_name, Effort.third.last_name])
      end

      it 'returns time data in the expected format' do
        get :spread, staging_id: event.staging_id
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].first.dig('attributes', 'displayStyle')).to eq('absolute')
        expect(parsed_response['included'].first.dig('attributes', 'absoluteTimes').flatten.map { |time| time.first(19) })
            .to match(Effort.third.split_times.map { |st| st.day_and_time.to_s.first(19).gsub(' ', 'T') })
      end
    end
  end

  describe '#import' do
    before do
      FactoryGirl.reload
      event.splits << splits
    end

    let(:course) { create(:course) }
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course_id: course.id) }
    let(:event) { create(:event, course_id: course.id, laps_required: 1) }

    context 'when provided with a file' do
      let(:request_params) { {staging_id: event.staging_id, data_format: 'csv_efforts', file: file} }
      let(:file) { file_fixture('test_efforts.csv') } # Should work in Rails 5

      it 'returns a successful json response' do
        skip 'Until Rails 5 upgrade'
        post :import, request_params
        expect(response.status).to eq(201)
      end

      it 'creates efforts' do
        skip 'Until Rails 5 upgrade'
        expect(Effort.all.size).to eq(0)
        post :import, request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(Effort.all.size).to eq(5)
      end

      it 'creates split_time records' do
        skip 'Until Rails 5 upgrade'
        expect(SplitTime.all.size).to eq(0)
        post :import, request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(SplitTime.all.size).to eq(23)
      end
    end

    context 'when provided with json data and data_format: :jsonapi' do
      let(:split_id) { splits.first.id }
      let(:request_params) { {staging_id: event.staging_id, data_format: 'jsonapi', data: data} }
      let(:data) { [
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, subSplitBitkey: 1, absoluteTime: '10:45:45 -06:00', withPacer: true, droppedHere: false}},
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, subSplitBitkey: 64, absoluteTime: '10:50:50 -06:00', withPacer: true, droppedHere: true}}
      ] }

      it 'returns a successful json response' do
        post :import, request_params
        expect(response.status).to eq(201)
      end

      it 'creates efforts' do
        expect(Effort.all.size).to eq(0)
        post :import, request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(Effort.all.size).to eq(5)
      end

      it 'creates split_time records' do
        expect(SplitTime.all.size).to eq(0)
        post :import, request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(SplitTime.all.size).to eq(23)
      end
    end
  end
end
