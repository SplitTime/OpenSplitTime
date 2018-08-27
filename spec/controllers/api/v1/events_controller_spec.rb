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
              .to match_array(Split.all.map(&:base_name))
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

      context 'when provided with a file having start_offset or start_time' do
        let(:request_params) { {id: event.id, data_format: 'csv_efforts', file: file} }
        let(:file) { fixture_file_upload(file_fixture('test_efforts_start_attributes.csv')) }

        it 'creates efforts and sets start offsets' do
          expect(Effort.all.size).to eq(0)
          make_request
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(3)
          expect(Effort.all.size).to eq(3)

          expect(Effort.all.pluck(:start_offset)).to match_array([0, 1800, 3600])
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
