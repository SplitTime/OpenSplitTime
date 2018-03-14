require 'rails_helper'

RSpec.describe Api::V1::EventsController do
  let(:type) { 'events' }
  let(:event) { create(:event, course: course, event_group: event_group) }
  let(:course) { create(:course) }
  let(:event_group) { create(:event_group) }

  describe '#index' do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

    before do
      create(:event)
      create(:event)
    end

    via_login_and_jwt do
      it 'returns a successful 200 response' do
        make_request
        expect(response.status).to eq(200)
      end

      context 'when no params are given' do
        it 'returns all available events' do
          make_request
          expect(response.status).to eq(200)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(2)
          expect(parsed_response['data'].map { |item| item['id'].to_i }.sort).to eq(Event.all.map(&:id).sort)
        end
      end
    end
  end

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing event.id is provided' do
        let(:params) { {id: event.id} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single event' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(event.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the event does not exist' do
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
    let(:params) { {data: {type: type, attributes: attributes}} }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:attributes) { {course_id: course.id, event_group_id: event_group.id, name: 'Test Event',
                            start_time_in_home_zone: '2017-03-01 06:00:00', laps_required: 1, home_time_zone: 'Eastern Time (US & Canada)'} }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(201)
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
        end

        it 'creates an event record with an id' do
          expect(Event.all.count).to eq(0)
          make_request
          expect(Event.all.count).to eq(1)
          expect(Event.first.id).not_to be_nil
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: event_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {name: 'Updated Event Name'} }

    via_login_and_jwt do
      context 'when the event exists' do
        let(:event_id) { event.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          event.reload
          expect(event.name).to eq(attributes[:name])
        end
      end

      context 'when the event does not exist' do
        let(:event_id) { 0 }

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
    subject(:make_request) { delete :destroy, params: {id: event_id} }

    via_login_and_jwt do
      context 'when the event exists' do
        let(:event_id) { event.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the event record' do
          event
          expect(Event.all.count).to eq(1)
          make_request
          expect(Event.all.count).to eq(0)
        end
      end

      context 'when the event does not exist' do
        let(:event_id) { 0 }
        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#spread' do
    subject(:make_request) { get :spread, params: params }
    let(:params) { {id: event_id} }
    let(:event_id) { event.id }
    before { Rails.cache.clear }

    via_login_and_jwt do
      context 'when the event exists' do
        let(:event_id) { event.id }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single event' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(event.id)
          expect(response.body).to be_jsonapi_response_for('event_spread_displays')
        end
      end

      context 'when the event does not exist' do
        let(:event_id) { 0 }

        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
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
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
              .to eq(Split.all.map(&:base_name))
        end

        it 'returns effort data in the expected format' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
              .to eq([Effort.third.last_name, Effort.first.last_name, Effort.second.last_name])
        end

        context 'when a sort param is provided' do
          let(:params) { {id: event.id, sort: 'last_name'} }

          it 'sorts effort data based on the sort param' do
            make_request
            parsed_response = JSON.parse(response.body)
            last_names = parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') }
            expect(last_names.sort).to eq(last_names)
          end
        end

        it 'returns time data in the expected format' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['included'].first.dig('attributes', 'displayStyle')).to eq('absolute')
          expect(parsed_response['included'].first.dig('attributes', 'absoluteTimes').flatten.map { |time| time.first(19) })
              .to match_array(Effort.third.split_times.map { |st| st.day_and_time.to_s.first(19).gsub(' ', 'T') })
        end
      end
    end
  end

  describe '#import' do
    subject(:make_request) { post :import, params: request_params }
    before do
      FactoryBot.reload
      event.splits << splits
    end

    before(:each) { VCR.insert_cassette("api/v1/events_controller", match_requests_on: [:host]) }
    after(:each) { VCR.eject_cassette }

    let(:course) { create(:course) }
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course: course) }
    let(:event_group) { create(:event_group) }
    let(:event) { create(:event, start_time_in_home_zone: '2016-07-01 06:00:00', event_group: event_group, course: course, laps_required: 1) }
    let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
    let(:absolute_time_in) { time_zone.parse('2016-07-01 10:45:45') }
    let(:absolute_time_out) { time_zone.parse('2016-07-01 10:50:50') }
    let(:effort) { create(:effort, event: event) }
    let(:bib_number) { effort.bib_number.to_s }
    let(:unique_key) { nil }

    via_login_and_jwt do
      context 'when provided with a file' do
        let(:request_params) { {id: event.id, data_format: 'csv_efforts', file: file} }
        let(:file) { fixture_file_upload(file_fixture('test_efforts_utf_8.csv')) }

        it 'creates efforts' do
          expect(Effort.all.size).to eq(0)
          make_request
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(3)
          expect(Effort.all.size).to eq(3)
        end
      end

      context 'when provided with an array of live_time hashes and data_format: :jsonapi_batch' do
        let(:split_id) { splits.first.id }
        let(:request_params) { {id: event.id, data_format: 'jsonapi_batch', data: data, unique_key: unique_key} }
        let(:data) { [
            {type: 'live_time',
             attributes: {bibNumber: bib_number, splitId: split_id, subSplitKind: 'in', absoluteTime: absolute_time_in,
                          withPacer: 'true', stoppedHere: 'false', source: source}},
            {type: 'live_time',
             attributes: {bibNumber: bib_number, splitId: split_id, subSplitKind: 'out', absoluteTime: absolute_time_out,
                          withPacer: 'true', stoppedHere: 'true', source: source}}
        ] }
        let(:source) { 'ost-remote-1234' }

        it 'creates live_times' do
          expect(LiveTime.all.size).to eq(0)
          make_request
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |record| record['type'] }).to all (eq('liveTimes'))
          expect(LiveTime.all.size).to eq(2)
          expect(LiveTime.all.map(&:bib_number)).to all eq(bib_number)
          expect(LiveTime.all.map(&:bitkey)).to eq([1, 64])
          expect(LiveTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
        end

        context 'when there is a duplicate live_time in the database' do
          before do
            create(:live_time, event: event, bib_number: bib_number, split_id: split_id, bitkey: 1, absolute_time: absolute_time_in, with_pacer: true, stopped_here: false, source: source)
          end

          context 'when unique_key is set' do
            let(:unique_key) { %w(absoluteTime splitId bitkey bibNumber source withPacer stoppedHere) }

            it 'saves the non-duplicate live_time to the database and updates the existing live_time' do
              expect(LiveTime.count).to eq(1)
              make_request
              expect(response.status).to eq(201)
              expect(LiveTime.count).to eq(2)
            end
          end

          context 'when unique_key is not set' do
            let(:unique_key) { nil }

            it 'returns the duplicate live_time and an error' do
              expect(LiveTime.count).to eq(1)
              make_request
              expect(response.status).to eq(422)
              expect(LiveTime.count).to eq(1)
            end
          end
        end

        context 'when there is a duplicate split_time in the database' do
          let(:split) { event.splits.first }
          let(:day_and_time) { time_zone.parse(absolute_time_in) }
          let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: 1, day_and_time: absolute_time_in, pacer: true, stopped_here: false) }

          it 'saves the live_times to the database and matches the duplicate live_time with the existing split_time' do
            expect(SplitTime.count).to eq(1)
            expect(LiveTime.count).to eq(0)
            make_request
            expect(response.status).to eq(201)
            expect(SplitTime.count).to eq(1)
            expect(LiveTime.count).to eq(2)
            expect(LiveTime.all.map(&:split_time_id)).to match_array([split_time.id, nil])
          end
        end

        context 'when there is a non-duplicate split_time in the database' do
          let(:effort) { create(:effort, event: event) }
          let(:split) { event.splits.first }
          let(:day_and_time) { time_zone.parse(absolute_time_in) }
          let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: 1, day_and_time: absolute_time_in + 2.minutes, pacer: true, stopped_here: false) }

          it 'saves the live_times to the database and does not match any live_time with the existing split_time' do
            expect(SplitTime.count).to eq(1)
            expect(LiveTime.count).to eq(0)
            make_request
            expect(response.status).to eq(201)
            expect(SplitTime.count).to eq(1)
            expect(LiveTime.count).to eq(2)
            expect(LiveTime.all.map(&:split_time_id)).to all be_nil
          end
        end

        context 'when the push notifications are permitted' do
          let(:event_group) { create(:event_group, available_live: true) }

          it 'sends a push notification that includes the count of available times' do
            expect(event.permit_notifications?).to be(true)
            allow(Pusher).to receive(:trigger)
            make_request
            expected_args = ["live-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 2, unmatched: 2}]
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
            make_request
            expect(LiveTime.all.size).to eq(2)
            expect(SplitTime.all.size).to eq(2)

            expect(LiveTime.all.pluck(:split_time_id).sort).to eq(SplitTime.all.pluck(:id).sort)
          end

          it 'sends a message to NotifyFollowersJob with relevant person and split_time data' do
            allow(NotifyFollowersJob).to receive(:perform_later) do |args|
              args[:split_time_ids].sort!
            end

            make_request
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
        let(:source_data) do
          VCR.use_cassette("adilas/#{url.split('?').last}") do
            Net::HTTP.get(URI(url))
          end
        end
        let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }

        it 'creates an effort and split_times' do
          expect(event.efforts.size).to eq(0)
          make_request
          expect(response.status).to eq(201)
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
  end
end
