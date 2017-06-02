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
      post :create, data: {type: 'events', attributes: params }
      expect(response.body).to be_jsonapi_response_for('events')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an event record with a staging_id' do
      expect(Event.all.count).to eq(0)
      post :create, data: {type: 'events', attributes: params }
      expect(Event.all.count).to eq(1)
      expect(Event.first.staging_id).not_to be_nil
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response' do
      put :update, staging_id: event.staging_id, data: {type: 'events', attributes: attributes }
      expect(response.body).to be_jsonapi_response_for('events')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, staging_id: event.staging_id, data: {type: 'events', attributes: attributes }
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, staging_id: 123, data: {type: 'events', attributes: attributes }
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
    let(:course) { create(:course, id: 10) }
    let(:event) { create(:event, course: course) }
    let(:params) { {as: :json, staging_id: event.id, data_format: 'race_result_times'} }
    let(:body) { {'list' => {'LastChange' => '2016-06-04 21:58:25',
                             'Orders' => [],
                             'Filters' => [],
                             'Fields' => [
                                 {'Expression' => "iif([RANK1]>0;[RANK1];\"*\")", 'Label' => 'Place'},
                                 {'Expression' => 'BIB', 'Label' => 'Bib'},
                                 {'Expression' => 'CorrectSpelling([DisplayName])', 'Label' => 'Name'},
                                 {'Expression' => 'SexMF', 'Label' => 'Sex'},
                                 {'Expression' => "iif([AGE]>0;[AGE];\"n/a\")", 'Label' => 'Age'},
                                 {'Expression' => 'Section1Split', 'Label' => 'Aid1'},
                                 {'Expression' => 'Section2Split', 'Label' => 'Aid2'},
                                 {'Expression' => 'Section3Split', 'Label' => 'Aid3'},
                                 {'Expression' => 'Section4Split', 'Label' => 'Aid4'},
                                 {'Expression' => 'Section5Split', 'Label' => 'Aid5'},
                                 {'Expression' => 'Section6Split', 'Label' => 'ToFinish'},
                                 {'Expression' => 'ElapsedTime', 'Label' => 'Elapsed'},
                                 {'Expression' => 'TimeOrStatus([ChipTime])', 'Label' => 'Time'},
                                 {'Expression' => "iif([TIMETEXT30]<>\"\" AND [STATUS]=0;[TIMETEXT30];\"*\")", 'Label' => 'Pace'}
                             ]},
                  'data' => {'#1_50k' => [['5', '3', '5', 'Jatest Schtest', 'M', '39', '0:43:01.36', '1:02:07.50', '0:52:34.70', '1:08:27.81', '0:51:23.93', '0:18:01.15', '4:55:36.43', '4:55:36.43', '09:30'],
                                          ['656', '28', '656', 'Tatest Notest', 'F', '26', '0:50:20.33', '1:14:15.40', '1:08:08.92', '1:18:06.69', '', '', '5:58:12.86', '5:58:12.86', '11:31'],
                                          ['324', '31', '324', 'Justest Rietest', 'M', '26', '0:50:06.26', '1:15:46.73', '1:07:10.94', '1:22:20.34', '1:05:15.36', '0:20:29.76', '6:01:09.37', '6:01:09.37', '11:37'],
                                          ['661', '*', '661', 'Castest Pertest', 'F', '31', '1:21:56.63', '2:38:01.85', '', '', '', '', '3:59:58.48', 'DNF', '*'],
                                          ['633', '*', '633', 'Mictest Hintest', 'F', '35', '', '', '', '', '', '', '', 'DNS', '*']]}
    } }

    it 'returns a successful json response' do
      post :import, params.merge(body)
      json_request = request.body
      expect(json_request).to be_nil
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates an event record with a staging_id' do
      expect(Event.all.count).to eq(0)
      post :import, data: {type: 'events', attributes: params }
      expect(Event.all.count).to eq(1)
      expect(Event.first.staging_id).not_to be_nil
    end
  end
end
