require 'rails_helper'

RSpec.describe Api::V1::EventsController do
  login_admin

  let(:event) { create(:event, course: course, event_group: event_group) }
  let(:course) { create(:course) }
  let(:event_group) { create(:event_group) }

  describe '#index' do
    before do
      create(:event)
      create(:event)
    end

    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    context 'when no params are given' do
      it 'returns all available events' do
        get :index

        expect(response.status).to eq(200)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(2)
        expect(parsed_response['data'].map { |item| item['id'].to_i }.sort).to eq(Event.all.map(&:id).sort)
      end
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, params: {id: event.id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :show, params: {id: event.id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('events')
    end

    it 'returns an error if the event does not exist' do
      get :show, params: {id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:params) { {course_id: course.id, event_group_id: event_group.id, name: 'Test Event',
                    start_time_in_home_zone: '2017-03-01 06:00:00', laps_required: 1, home_time_zone: 'Eastern Time (US & Canada)'} }

    it 'returns a successful json response' do
      post :create, params: {data: {type: 'events', attributes: params}}
      expect(response.body).to be_jsonapi_response_for('events')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an event record with an id' do
      expect(Event.all.count).to eq(0)
      post :create, params: {data: {type: 'events', attributes: params}}
      expect(Event.all.count).to eq(1)
      expect(Event.first.id).not_to be_nil
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response' do
      put :update, params: {id: event.id, data: {type: 'events', attributes: attributes}}
      expect(response.body).to be_jsonapi_response_for('events')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, params: {id: event.id, data: {type: 'events', attributes: attributes}}
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, params: {id: 123, data: {type: 'events', attributes: attributes}}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, params: {id: event.id}
      expect(response.status).to eq(200)
    end

    it 'destroys the event record' do
      test_event = event
      expect(Event.all.count).to eq(1)
      delete :destroy, params: {id: test_event.id}
      expect(Event.all.count).to eq(0)
    end

    it 'returns an error if the event does not exist' do
      delete :destroy, params: {id: 123}
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
      get :spread, params: {id: event.id}
      expect(response.status).to eq(200)
    end

    it 'returns data of a single event' do
      get :spread, params: {id: event.id}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(event.id)
      expect(response.body).to be_jsonapi_response_for('event_spread_displays')
    end

    it 'returns an error if the event does not exist' do
      get :spread, params: {id: 123}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end

    context 'when split and effort data are available' do
      before do
        FactoryBot.reload
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
        get :spread, params: {id: event.id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
            .to eq(Split.all.map(&:base_name))
      end

      it 'returns effort data in the expected format' do
        get :spread, params: {id: event.id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
            .to eq([Effort.third.last_name, Effort.first.last_name, Effort.second.last_name])
      end

      it 'sorts effort data based on the sort param' do
        get :spread, params: {id: event.id, sort: 'last_name'}
        parsed_response = JSON.parse(response.body)
        last_names = parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') }
        expect(last_names.sort).to eq(last_names)
      end

      it 'returns time data in the expected format' do
        get :spread, params: {id: event.id}
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['included'].first.dig('attributes', 'displayStyle')).to eq('absolute')
        expect(parsed_response['included'].first.dig('attributes', 'absoluteTimes').flatten.map { |time| time.first(19) })
            .to match_array(Effort.third.split_times.map { |st| st.day_and_time.to_s.first(19).gsub(' ', 'T') })
      end
    end
  end

  describe '#import' do
    before do
      FactoryBot.reload
      event.splits << splits
    end

    let(:course) { create(:course) }
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course: course) }
    let(:event_group) { create(:event_group) }
    let(:event) { create(:event, start_time: '2016-07-01 00:00:00 GMT', event_group: event_group, course: course, laps_required: 1) }
    let(:absolute_time_in) { '2016-07-01 10:45:45-06:00' }
    let(:absolute_time_out) { '2016-07-01 10:50:50-06:00' }
    let(:unique_key) { nil }

    context 'when provided with a file' do
      let(:request_params) { {id: event.id, data_format: 'csv_efforts', file: file} }
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
        post :import, params: request_params
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['message']).to match(/Import complete/)
        expect(SplitTime.all.size).to eq(23)
      end
    end

    context 'when provided with an array of live_time hashes and data_format: :jsonapi_batch' do
      let(:split_id) { splits.first.id }
      let(:request_params) { {id: event.id, data_format: 'jsonapi_batch', data: data, unique_key: unique_key} }
      let(:data) { [
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, subSplitKind: 'in', absoluteTime: absolute_time_in,
                        withPacer: 'true', stoppedHere: 'false', source: source}},
          {type: 'live_time',
           attributes: {bibNumber: '101', splitId: split_id, subSplitKind: 'out', absoluteTime: absolute_time_out,
                        withPacer: 'true', stoppedHere: 'true', source: source}}
      ] }
      let(:source) { 'ost-remote-1234' }

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
        expect(LiveTime.all.map(&:bib_number)).to eq(%w[101 101])
        expect(LiveTime.all.map(&:bitkey)).to eq([1, 64])
        expect(LiveTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
      end

      context 'when there is a duplicate record in the database' do
        before do
          create(:live_time, event: event, bib_number: '101', split_id: split_id, bitkey: 1, absolute_time: absolute_time_in, with_pacer: true, stopped_here: false, source: source)
        end

        context 'when unique_key is set' do
          let(:unique_key) { %w(absoluteTime splitId bitkey bibNumber source withPacer stoppedHere) }

          it 'saves the non-duplicate live_time to the database and updates the existing live_time' do
            expect(LiveTime.count).to eq(1)
            post :import, params: request_params
            expect(response.status).to eq(201)
            expect(LiveTime.count).to eq(2)
          end
        end

        context 'when unique_key is not set' do
          let(:unique_key) { nil }

          it 'returns the duplicate live_time and an error' do
            expect(LiveTime.count).to eq(1)
            post :import, params: request_params
            expect(response.status).to eq(422)
            expect(LiveTime.count).to eq(1)
          end
        end
      end

      context 'when the event_group is available live' do
        let(:event_group) { create(:event_group, available_live: true) }

        it 'sends a push notification that includes the count of available times' do
          allow(Pusher).to receive(:trigger)
          post :import, params: request_params
          expected_args = ["live_times_available_#{event.id}", 'update', {count: 2}]
          expect(Pusher).to have_received(:trigger).with(*expected_args)
        end
      end

      context 'when the event_group is available live and auto_live_times is true' do
        let!(:event_group) { create(:event_group, available_live: true, auto_live_times: true) }
        let!(:effort) { create(:effort, event: event, bib_number: 101, person: person) }
        let!(:person) { create(:person) }
        let(:data) { [
            {type: 'live_time',
             attributes: {bibNumber: '101', splitId: splits.second.id, bitkey: 1, absoluteTime: absolute_time_in,
                          withPacer: true, stoppedHere: false, source: source}},
            {type: 'live_time',
             attributes: {bibNumber: '101', splitId: splits.second.id, bitkey: 64, absoluteTime: absolute_time_out,
                          withPacer: true, stoppedHere: true, source: source}}
        ] }

        it 'creates new split_times matching the live_times' do
          post :import, params: request_params
          expect(LiveTime.all.size).to eq(2)
          expect(SplitTime.all.size).to eq(2)

          expect(LiveTime.all.pluck(:split_time_id).sort).to eq(SplitTime.all.pluck(:id).sort)
        end

        it 'sends a message to NotifyFollowersJob with relevant person and split_time data' do
          allow(NotifyFollowersJob).to receive(:perform_later) do |args|
            args[:split_time_ids].sort!
          end

          post :import, params: request_params
          split_time_ids = SplitTime.all.ids
          person_id = SplitTime.first.effort.person_id

          expect(NotifyFollowersJob).to have_received(:perform_later)
                                            .with(person_id: person_id,
                                                  split_time_ids: split_time_ids.sort,
                                                  multi_lap: false)
        end

        it 'sends a message to Interactors::UpdateEffortsStatus with the efforts associated with the modified split_times' do
          allow(Interactors::UpdateEffortsStatus).to receive(:perform!)
          post :import, params: request_params
          efforts = Effort.where(id: SplitTime.all.pluck(:effort_id).uniq)

          expect(Interactors::UpdateEffortsStatus).to have_received(:perform!).with(efforts)
        end
      end
    end

    context 'when provided with an adilas url and data_format adilas_bear_times' do
      let(:request_params) { {id: event.id, data_format: 'adilas_bear_times', data: source_data} }
      let(:source_data) { Net::HTTP.get(URI(url)) }
      let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }

      it 'returns a successful json response' do
        post :import, params: request_params
        expect(response.status).to eq(201)
      end

      it 'creates an effort and split_times' do
        expect(event.efforts.size).to eq(0)
        post :import, params: request_params
        event.reload
        expect(event.efforts.size).to eq(1)
        effort = event.efforts.first
        expect(effort.first_name).to eq('Linda')
        expect(effort.last_name).to eq('McFadden')
        split_times = event.efforts.first.split_times
        expect(split_times.size).to eq(7)
        expect(split_times.map(&:time_from_start)).to match_array([0.0, 10150.0, 10150.0, 23427.0, 23429.0, 28151.0, 114551.0])
      end
    end
  end

  describe '#trigger_live_times_push' do
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course_id: course.id) }
    let(:request_params) { {id: event.id} }

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
