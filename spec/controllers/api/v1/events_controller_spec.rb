# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::EventsController do
  let(:type) { 'events' }
  let(:event) { create(:event, course: course, event_group: event_group) }
  let(:course) { create(:course) }
  let(:event_group) { create(:event_group) }

  describe '#index' do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

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
          expect(parsed_response['data'].map { |item| item['id'].to_i }).to match_array(Event.all.map(&:id).sort)
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
        let(:attributes) { {course_id: course.id, event_group_id: event_group.id, short_name: '50M',
                            start_time_local: '2017-03-01 06:00:00', laps_required: 1} }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(201)
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
        end

        it 'creates an event record with an id' do
          expect { make_request }.to change { Event.count }.by(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: event_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {short_name: 'Updated Short Name'} }

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
          expect(event.short_name).to eq(attributes[:short_name])
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
        let!(:event) { create(:event) }
        let(:event_id) { event.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the event record' do
          expect { make_request }.to change { Event.count }.by(-1)
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
    let(:params) { {id: event_id, display_style: display_style} }
    let(:event_id) { event.id }
    let(:display_style) { 'absolute' }
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
        let(:event) { events(:hardrock_2015) }

        context 'when display_style is not provided' do
          it 'returns split data in the expected format' do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response.dig('data', 'attributes', 'splitHeaderData').map { |header| header['title'] })
                .to match_array(event.splits.map(&:base_name))
          end

          it 'returns effort data in the expected format' do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['included'].map { |effort| effort.dig('attributes', 'lastName') })
                .to match_array(event.efforts.map(&:last_name))
          end

          it 'returns time data in absolute time format' do
            make_request
            parsed_response = JSON.parse(response.body)
            subject_row = parsed_response['included'].first
            subject_effort = Effort.find(subject_row['id'])
            expect(subject_row.dig('attributes', 'displayStyle')).to eq('absolute')

            response_times = subject_row.dig('attributes', 'absoluteTimes').flatten.map(&:in_time_zone)
            expected_times = subject_effort.split_times.map(&:absolute_time)
            expect(response_times).to match_array(expected_times)
          end
        end

        context 'when display_style is elapsed' do
          let(:display_style) { 'elapsed' }

          it 'returns time data in absolute time format' do
            make_request
            parsed_response = JSON.parse(response.body)
            subject_row = parsed_response['included'].first
            subject_effort = Effort.find(subject_row['id'])
            expect(subject_row.dig('attributes', 'displayStyle')).to eq('elapsed')

            response_times = subject_row.dig('attributes', 'elapsedTimes').flatten
            expected_times = subject_effort.split_times.map(&:time_from_start)
            expect(response_times).to match_array(expected_times)
          end
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
      end
    end
  end

  describe '#import' do
    subject(:make_request) { post :import, params: request_params }
    before(:each) { VCR.insert_cassette("api/v1/events_controller", match_requests_on: [:host]) }
    after(:each) { VCR.eject_cassette }

    let(:event) { events(:ggd30_50k) }
    let(:event_group) { event.event_group }

    via_login_and_jwt do
      context 'when provided with a file' do
        let(:request_params) { {id: event.id, data_format: 'csv_efforts', file: file} }
        let(:file) { fixture_file_upload(file_fixture('test_efforts_utf_8.csv')) }

        it 'creates efforts' do
          expect { make_request }.to change { Effort.count }.by(3)
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(3)
        end
      end

      context 'when provided with a file having start_time or start_offset' do
        let(:request_params) { {id: event.id, data_format: 'csv_efforts', file: file} }
        let(:file) { fixture_file_upload(file_fixture('test_efforts_start_attributes.csv')) }

        it 'sets scheduled_start_time based on the start_time or start_offset or event start_time' do
          expect { make_request }.to change { Effort.count }.by(3)
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].size).to eq(3)

          start_times = parsed_response['data'].map { |row| row['attributes']['scheduledStartTime']&.in_time_zone(event_group.home_time_zone) }
          expected_absolute_times = ['2017-06-03 19:30:00 -0600',
                                     '2017-06-03 08:00:00 -0600',
                                     '2017-06-03 19:00:00 -0600']
          expect(start_times).to eq(expected_absolute_times)
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
          expect { make_request }.to change { event.efforts.count }.by(1)
          expect(response.status).to eq(201)
          event.reload
          effort = event.efforts.last
          expect(effort.first_name).to eq('Linda')
          expect(effort.last_name).to eq('McFadden')
          split_times = effort.ordered_split_times
          expect(split_times.size).to eq(7)
          expected_absolute_times = ['2016-09-23 06:00:00 -0600',
                                     '2016-09-23 08:49:10 -0600',
                                     '2016-09-23 08:49:10 -0600',
                                     '2016-09-23 12:30:27 -0600',
                                     '2016-09-23 12:30:29 -0600',
                                     '2016-09-24 13:49:11 -0600',
                                     '2016-09-23 13:49:11 -0600']

          expect(split_times.map(&:absolute_time)).to eq(expected_absolute_times)
        end
      end

      context 'when provided with JSON data from api.raceresult.com and data_format race_result_api_times' do
        let(:request_params) { {id: event.id, data_format: 'race_result_api_times', data: source_data} }
        let(:source_data) do
          {"list" =>
               {"list_name" => "Result Lists|Tracking Details - json for API",
                "orders" => [],
                "filters" => [{"expression1" => "CONTEST", "expression2" => "1", "operator" => "=", "or_conjunction" => false}],
                "fields" => [{"alignment" => 1, "expression" => "\"#\" & [BIB] & \". \" & ucase([FLNAME])"},
                             {"alignment" => 1, "expression" => "\"STATUS: \" & [STATUSTEXT]"},
                             {"alignment" => 1, "expression" => "\"START\""},
                             {"alignment" => 1, "expression" => "iif([TIMESET100];\"Time: \" & format(T100;\"Hh:mm:ss A\"))"},
                             {"alignment" => 1, "expression" => "\"AID 1\""},
                             {"alignment" => 1, "expression" => "iif([TIMESET151];\"Time: \" & format(T151;\"Hh:mm:ss A\"))", "line" => 3},
                             {"alignment" => 1, "expression" => "iif([TIMESET151];\"Split: \" & [Section1Split])", "line" => 3},
                             {"alignment" => 1, "expression" => "\"AID 2\"", "line" => 4},
                             {"alignment" => 1, "expression" => "iif([TIMESET152];\"Time: \" & format(T152;\"Hh:mm:ss A\"))", "line" => 4},
                             {"alignment" => 1, "expression" => "iif([TIMESET152];\"Split: \" & [Section2Split])", "line" => 4},
                             {"alignment" => 1, "expression" => "\"AID 3\"", "line" => 5},
                             {"alignment" => 1, "expression" => "iif([TIMESET153];\"Time: \" & format(T153;\"Hh:mm:ss A\"))", "line" => 5},
                             {"alignment" => 1, "expression" => "iif([TIMESET153];\"Split: \" & [Section3Split])", "line" => 5},
                             {"alignment" => 1, "expression" => "\"AID 4\"", "line" => 6},
                             {"alignment" => 1, "expression" => "iif([TIMESET154];\"Time: \" & format(T154;\"Hh:mm:ss A\"))", "line" => 6},
                             {"alignment" => 1, "expression" => "iif([TIMESET154];\"Split: \" & [Section4Split])", "line" => 6},
                             {"alignment" => 1, "expression" => "\"AID 5\"", "line" => 7},
                             {"alignment" => 1, "expression" => "iif([TIMESET155];\"Time: \" & format(T155;\"Hh:mm:ss A\"))", "line" => 7},
                             {"alignment" => 1, "expression" => "iif([TIMESET155];\"Split: \" & [Section6Split])", "line" => 7},
                             {"alignment" => 1, "expression" => "\"FINISH\"", "line" => 8},
                             {"alignment" => 1, "expression" => "iif([TIMESET200];\"Time: \" & format(T200;\"Hh:mm:ss A\"))", "line" => 8},
                             {"alignment" => 1, "expression" => "iif([TIMESET200];\"Total Time: \" & [TIMETEXT])", "line" => 8}]},
           "data" => {"#1_50k" => [[1116, "#1116. FINISHED FIRST", "STATUS: OK", "START", "Time: 8:01:49 AM", "AID 1", "Time: 8:41:08 AM", "Split: 0:39:19.11", "AID 2", "Time: 9:38:32 AM", "Split: 0:57:23.56", "AID 3", "Time: 10:24:12 AM", "Split: 0:45:39.80", "AID 4", "Time: 11:29:45 AM", "Split: 1:05:33.06", "AID 5", "Time: 12:20:44 PM", "Split: 0:10:44.34", "FINISH", "Time: 12:37:41 PM", "Total Time: 4:35:52.1"],
                                   [1117, "#1117. FINISHED SECOND", "STATUS: OK", "START", "Time: 8:01:48 AM", "AID 1", "", "", "AID 2", "Time: 9:41:07 AM", "Split: 0:59:30.85", "AID 3", "Time: 10:31:45 AM", "Split: 0:50:38.20", "AID 4", "Time: 11:40:33 AM", "Split: 1:08:48.08", "AID 5", "Time: 12:31:31 PM", "Split: 0:18:31.84", "FINISH", "Time: 12:48:04 PM", "Total Time: 4:46:15.7"],
                                   [1118, "#1118. PROGRESS AID4", "STATUS: OK", "START", "Time: 6:08:18 AM", "AID 1", "Time: 7:27:44 AM", "Split: 1:19:26.03", "AID 2", "Time: 9:31:50 AM", "Split: 2:04:05.72", "AID 3", "Time: 11:36:00 AM", "Split: 2:04:09.50", "AID 4", "Time: 14:26:38 PM", "Split: 2:50:37.96", "AID 5", "Time: 16:38:50 PM", "Split: 0:37:50.18", "FINISH", "Time: 17:22:12 PM", "Total Time: 11:13:54.0"],
                                   [219, "#219. PROGRESS AID3", "STATUS: OK", "START", "Time: 6:08:18 AM", "AID 1", "Time: 7:38:18 AM", "Split: 1:30:00.00", "AID 2", "", "", "AID 3", "", "", "AID 4", "", "", "AID 5", "", "", "FINISH", "", ""],
                                   [433, "#433. START ONLY", "STATUS: OK", "START", "Time: 8:01:49 AM", "AID 1", "", "", "AID 2", "", "", "AID 3", "", "", "AID 4", "", "", "AID 5", "", "", "FINISH", "", ""]]}
          }.to_json
        end

        context 'when existing efforts have no split times' do
          before do
            event.efforts.each do |effort|
              effort.split_times.each(&:destroy)
            end
          end

          it 'adds times to existing efforts' do
            expect { make_request }.to change { event.efforts.count }.by(0)
            expect(response.status).to eq(201)
            event.reload

            effort = event.efforts.find_by(bib_number: 1116)
            split_times = effort.ordered_split_times
            expect(split_times.size).to eq(7)
            expected_absolute_times = ['2017-06-03 08:01:49 -0600',
                                       '2017-06-03 08:41:08 -0600',
                                       '2017-06-03 09:38:32 -0600',
                                       '2017-06-03 10:24:12 -0600',
                                       '2017-06-03 11:29:45 -0600',
                                       '2017-06-03 12:20:44 -0600',
                                       '2017-06-03 12:37:41 -0600']
            expect(split_times.map(&:absolute_time)).to eq(expected_absolute_times)

            effort = event.efforts.find_by(bib_number: 433)
            split_times = effort.ordered_split_times
            expect(split_times.size).to eq(1)
            expected_absolute_times = ['2017-06-03 08:01:49 -0600']
            expect(split_times.map(&:absolute_time)).to eq(expected_absolute_times)
          end
        end

        context 'when existing efforts have existing split times' do
          it 'overwrites existing times but does not erase existing times when blanks appear' do
            expect { make_request }.to change { event.efforts.count }.by(0)
            expect(response.status).to eq(201)
            event.reload

            effort = event.efforts.find_by(bib_number: 1116)
            split_times = effort.ordered_split_times
            expect(split_times.size).to eq(7)
            expected_absolute_times = ['2017-06-03 08:01:49 -0600',
                                       '2017-06-03 08:41:08 -0600',
                                       '2017-06-03 09:38:32 -0600',
                                       '2017-06-03 10:24:12 -0600',
                                       '2017-06-03 11:29:45 -0600',
                                       '2017-06-03 12:20:44 -0600',
                                       '2017-06-03 12:37:41 -0600']
            expect(split_times.map(&:absolute_time)).to eq(expected_absolute_times)

            effort = event.efforts.find_by(bib_number: 1117)
            split_times = effort.ordered_split_times
            expect(split_times.size).to eq(7)
            expected_absolute_times = ['2017-06-03 08:01:48 -0600',
                                       '2017-06-03 07:52:00 -0600',
                                       '2017-06-03 09:41:07 -0600',
                                       '2017-06-03 10:31:45 -0600',
                                       '2017-06-03 11:40:33 -0600',
                                       '2017-06-03 12:31:31 -0600',
                                       '2017-06-03 12:48:04 -0600']
            expect(split_times.map(&:absolute_time)).to eq(expected_absolute_times)
          end
        end
      end
    end
  end
end
