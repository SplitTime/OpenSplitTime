require 'rails_helper'

describe Api::V1::EventsController do
  login_admin

  let(:event) { create(:event, course: course) }
  let(:course) { create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {staging_id: event.id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :show, params: {staging_id: event.id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('events')
    end

    it 'returns an error if the event does not exist' do
      get :show, params: {staging_id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:params) { {course_id: course.id, name: 'Test Event', start_time_in_home_zone: '2017-03-01 06:00:00', laps_required: 1, home_time_zone: 'Eastern Time (US & Canada)'} }

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
      put :update, params: {staging_id: event.id, data: {type: 'events', attributes: attributes }}
      expect(response.body).to be_jsonapi_response_for('events')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {staging_id: event.id, data: {type: 'events', attributes: attributes }}
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, params: {staging_id: 123, data: {type: 'events', attributes: attributes }}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {staging_id: event.id}
      expect(response.status).to eq(200)
    end

    it 'destroys the event record' do
      test_event = event
      expect(Event.all.count).to eq(1)
      delete :destroy, params: {staging_id: test_event.id}
      expect(Event.all.count).to eq(0)
    end

    it 'returns an error if the event does not exist' do
      delete :destroy, params: {staging_id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#spread' do
    before do
      Rails.cache.clear
    end

    it 'returns a successful 200 response' do
      get :spread, params: {staging_id: event.id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :spread, params: {staging_id: event.id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('event_spread_displays')
    end

    it 'returns data from cache if the cache is valid' do
      skip 'caching in test environment is disabled'
      expect(EventSpreadDisplay).to receive(:new).once.and_call_original
      get :spread, params: {staging_id: event.id}
      get :spread, params: {staging_id: event.id}
    end

    it 'returns an error if the event does not exist' do
      get :spread, params: {staging_id: 123}
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
        get :spread, params: {staging_id: event.id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
            .to eq(Split.all.map(&:base_name))
      end

      it 'returns effort data in the expected format' do
        get :spread, params: {staging_id: event.id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.third.last_name, Effort.first.last_name, Effort.second.last_name])
      end

      it 'sorts effort data based on the sort param' do
        get :spread, params: {staging_id: event.id, sort: 'last_name'}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.first.last_name, Effort.second.last_name, Effort.third.last_name])
      end

      it 'returns time data in the expected format' do
        get :spread, params: {staging_id: event.id}
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
      let(:request_params) { {staging_id: event.id, data_format: 'csv_efforts', file: file} }
      let(:file) { file_fixture('test_efforts.csv') } # Should work in Rails 5

      it 'returns a successful json response' do
        skip 'Until Rails 5 upgrade'
        post :import, params: request_params
        expect(response.status).to eq(201)
      end

      it 'creates efforts' do
        skip 'Until Rails 5 upgrade'
        expect(Effort.all.size).to eq(0)
        post :import, params: request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(Effort.all.size).to eq(5)
      end

      it 'creates split_time records' do
        skip 'Until Rails 5 upgrade'
        expect(SplitTime.all.size).to eq(0)
        post :import, params:  request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(SplitTime.all.size).to eq(23)
      end
    end

    context 'when provided with an array of live_time hashes and data_format: :jsonapi_batch' do
      let(:split_id) { splits.first.id }
      let(:request_params) { {staging_id: event.id, data_format: 'jsonapi_batch', data: data} }
      let(:data) { [
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, bitkey: 1, absoluteTime: '10:45:45-06:00',
                        withPacer: true, stoppedHere: false, source: 'ost-remote-1234'}},
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, bitkey: 64, absoluteTime: '10:50:50-06:00',
                        withPacer: true, stoppedHere: true, source: 'ost-remote-1234'}}
      ] }

      it 'returns a successful json response' do
        post :import, params: request_params
        expect(response.status).to eq(201)
      end

      it 'creates live_times' do
        expect(LiveTime.all.size).to eq(0)
        post :import, params: request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].map { |record| record['type'] }).to all (eq('liveTimes'))
        expect(LiveTime.all.size).to eq(2)
      end

      it 'assigns attributes correctly' do
        post :import, params: request_params
        expect(LiveTime.all.map(&:bib_number)).to eq([101, 101])
        expect(LiveTime.all.map(&:bitkey)).to eq([1, 64])
        expect(LiveTime.all.map(&:absolute_time)).to eq(%w(10:45:45-06:00 10:50:50-06:00))
      end

      context 'when the event is available live' do
        let(:event) { create(:event, course_id: course.id, laps_required: 1, available_live: true) }

        it 'sends a push notification that includes the count of available times' do
          allow(Pusher).to receive(:trigger)
          post :import, params: request_params
          expected_args = ["live_times_available_#{event.id}", 'update', {count: 2}]
          expect(Pusher).to have_received(:trigger).with(*expected_args)
        end
      end

      context 'when the event is available live and auto_live_times is true' do
        let!(:event) { create(:event, course_id: course.id, laps_required: 1, available_live: true, auto_live_times: true) }
        let!(:effort) { create(:effort, event: event, bib_number: 101) }
        let(:data) { [
            {type: 'live_time',
             attributes: {bibNumber: '101', splitId: splits.second.id, bitkey: 1, absoluteTime: '10:45:45-06:00',
                          withPacer: true, stoppedHere: false, source: 'ost-remote-1234'}},
            {type: 'live_time',
             attributes: {bibNumber: '101', splitId: splits.second.id, bitkey: 64, absoluteTime: '10:50:50-06:00',
                          withPacer: true, stoppedHere: true, source: 'ost-remote-1234'}}
        ] }

        it 'creates new split_times matching the live_times' do
          post :import, params: request_params
          expect(LiveTime.all.size).to eq(2)
          expect(SplitTime.all.size).to eq(2)

          expect(LiveTime.all.pluck(:split_time_id).sort).to eq(SplitTime.all.pluck(:id).sort)
        end

        it 'sends a message to NotifyFollowersJob with relevant person and split_time data' do
          allow(NotifyFollowersJob).to receive(:perform_later)
          post :import, params: request_params
          split_time_ids = SplitTime.all.ids.sort.reverse
          person_id = SplitTime.first.effort.person_id

          expect(NotifyFollowersJob).to have_received(:perform_later)
                                            .with({person_id: person_id,
                                                   split_time_ids: split_time_ids,
                                                   multi_lap: false})
        end

        it 'sends a message to EffortDataStatusSetter with the effort associated with the modified split_times' do
          allow(EffortDataStatusSetter).to receive(:set_data_status)
          post :import, params: request_params
          effort = SplitTime.first.effort

          expect(EffortDataStatusSetter).to have_received(:set_data_status)
                                            .with(effort: effort)
        end
      end
    end
  end

  describe '#trigger_live_times_push' do
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course_id: course.id) }
    let(:request_params) { {staging_id: event.id} }

    it 'sends a push notification that includes the count of available times' do
      event.splits << splits
      create_list(:live_time, 3, event: event, split: splits.first)
      allow(Pusher).to receive(:trigger)
      get :trigger_live_times_push, params: request_params
      expected_args = ["live_times_available_#{event.id}", 'update', {count: 3}]
      expect(Pusher).to have_received(:trigger).with(*expected_args)
    end
  end
end
