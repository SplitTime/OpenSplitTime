# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Api::V1::EventGroupsController do
  let(:event_group) { create(:event_group, data_entry_grouping_strategy: 'location_grouped') }
  let(:type) { 'event_groups' }
  let(:stub_combined_split_attributes) { true }

  before do
    if stub_combined_split_attributes
      allow(CombineEventGroupSplitAttributes)
          .to receive(:perform).and_return(['EventGroup#combined_split_attributes is stubbed for testing'])
    end
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

        context 'when combined_split_attributes is not stubbed' do
          let(:stub_combined_split_attributes) { false }
          let(:event_1) { create(:event, event_group: event_group, course: course_1) }
          let(:event_2) { create(:event, event_group: event_group, course: course_2) }
          let(:course_1) { create(:course) }
          let(:course_2) { create(:course) }

          let(:event_1_split_1) { create(:split, :start, course: course_1, base_name: 'Start', latitude: 40, longitude: -105) }
          let(:event_1_split_2) { create(:split, course: course_1, base_name: 'Aid 1', latitude: 41, longitude: -106) }
          let(:event_1_split_3) { create(:split, course: course_1, base_name: 'Aid 2', latitude: 42, longitude: -107) }
          let(:event_1_split_4) { create(:split, :finish, course: course_1, base_name: 'Finish', latitude: 40, longitude: -105) }
          let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }

          let(:event_2_split_1) { create(:split, :start, course: course_2, base_name: 'Start', latitude: 40, longitude: -105) }
          let(:event_2_split_2) { create(:split, course: course_2, base_name: 'Aid 2', latitude: 42, longitude: -107) }
          let(:event_2_split_3) { create(:split, :finish, course: course_2, base_name: 'Finish', latitude: 40, longitude: -105) }
          let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

          let(:event_1_id) { event_1.id.to_s }
          let(:event_2_id) { event_2.id.to_s }

          let(:expected) {
            [
                {'title' => 'Start/Finish',
                 'entries' =>
                     [{'subSplitKind' => 'in',
                       'label' => 'Start',
                       'splitName' => 'Start',
                       'parameterizedSplitName' => 'start'},
                      {'subSplitKind' => 'in',
                       'label' => 'Finish',
                       'splitName' => 'Finish',
                       'parameterizedSplitName' => 'finish'}]},
                {'title' => 'Aid 1',
                 'entries' =>
                     [{'subSplitKind' => 'in',
                       'label' => 'Aid 1 In',
                       'splitName' => 'Aid 1',
                       'parameterizedSplitName' => 'aid-1'},
                      {'subSplitKind' => 'out',
                       'label' => 'Aid 1 Out',
                       'splitName' => 'Aid 1',
                       'parameterizedSplitName' => 'aid-1'}]},
                {'title' => 'Aid 2',
                 'entries' =>
                     [{'subSplitKind' => 'in',
                       'label' => 'Aid 2 In',
                       'splitName' => 'Aid 2',
                       'parameterizedSplitName' => 'aid-2'},
                      {'subSplitKind' => 'out',
                       'label' => 'Aid 2 Out',
                       'splitName' => 'Aid 2',
                       'parameterizedSplitName' => 'aid-2'}]}
            ]
          }

          before do
            event_1.splits << event_1_splits
            event_2.splits << event_2_splits
          end

          it 'includes a dataEntryGroups key containing information mapping aid station names to relevant data entry information' do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['data']['attributes']['dataEntryGroups']).to eq(expected)
            expect(response.body).to be_jsonapi_response_for(type)
          end
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

  describe '#import' do
    subject(:make_request) { post :import, params: request_params }
    before do
      FactoryBot.reload
      event.splits << splits
    end

    before(:each) { VCR.insert_cassette("api/v1/event_groups_controller", match_requests_on: [:host]) }
    after(:each) { VCR.eject_cassette }

    let(:course) { create(:course) }
    let(:splits) { create_list(:splits_hardrock_ccw, 4, course: course) }
    let(:event_group) { create(:event_group) }
    let(:event) { create(:event, start_time_local: '2016-07-01 06:00:00', event_group: event_group, course: course, laps_required: 1) }
    let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
    let(:absolute_time_in) { time_zone.parse('2016-07-01 10:45:45') }
    let(:absolute_time_out) { time_zone.parse('2016-07-01 10:50:50') }
    let(:effort) { create(:effort, event: event) }
    let(:bib_number) { effort.bib_number.to_s }
    let(:strict) { nil }
    let(:unique_key) { nil }
    let(:limited_response) { nil }

    context 'when provided with an array of raw_time hashes and data_format: :jsonapi_batch' do
      let(:split_name) { splits.first.name }
      let(:request_params) { {id: event_group.id, data_format: 'jsonapi_batch', data: data, strict: strict, unique_key: unique_key, limited_response: limited_response} }
      let(:data) { [
          {type: 'raw_time',
           attributes: {bibNumber: bib_number, splitName: split_name, subSplitKind: 'in', absoluteTime: absolute_time_in,
                        withPacer: 'true', stoppedHere: 'false', source: source}},
          {type: 'raw_time',
           attributes: {bibNumber: bib_number, splitName: split_name, subSplitKind: 'out', absoluteTime: absolute_time_out,
                        withPacer: 'true', stoppedHere: 'true', source: source}}
      ] }
      let(:source) { 'ost-remote-1234' }

      context 'when raw_time data is valid' do
        via_login_and_jwt do
          it 'creates raw_times' do
            expect(RawTime.all.size).to eq(0)
            make_request
            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['data'].map { |record| record['type'] }).to all (eq('rawTimes'))
            expect(RawTime.all.size).to eq(2)
            expect(RawTime.all.map(&:bib_number)).to all eq(bib_number)
            expect(RawTime.all.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(RawTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
            expect(RawTime.all.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context 'when one raw_time is valid and another raw_time is invalid' do
        via_login_and_jwt do
          let(:data) { [
              {type: 'raw_time',
               attributes: {bibNumber: nil, splitName: split_name, subSplitKind: 'in', absoluteTime: absolute_time_in,
                            withPacer: 'true', stoppedHere: 'false', source: source}},
              {type: 'raw_time',
               attributes: {bibNumber: bib_number, splitName: split_name, subSplitKind: 'out', absoluteTime: absolute_time_out,
                            withPacer: 'true', stoppedHere: 'true', source: source}}
          ] }

          it 'does not create any raw_times and returns 422' do
            expect(RawTime.all.size).to eq(0)
            make_request
            expect(response.status).to eq(422)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['errors'].first.dig('detail', 'messages')).to include("Bib number can't be blank")
            expect(RawTime.all.size).to eq(0)
          end
        end
      end

      context 'when params[:strict] is "true"' do
        via_login_and_jwt do
          let(:strict) { true }

          it 'creates raw_times and returns 201' do
            expect(RawTime.all.size).to eq(0)
            make_request
            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['data'].map { |record| record['type'] }).to all (eq('rawTimes'))
            expect(RawTime.all.size).to eq(2)
            expect(RawTime.all.map(&:bib_number)).to all eq(bib_number)
            expect(RawTime.all.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(RawTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
            expect(RawTime.all.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context 'when params[:limited_response] is "true"' do
        via_login_and_jwt do
          let(:limited_response) { true }

          it 'creates raw_times and returns 201 without sending other data' do
            expect(RawTime.all.size).to eq(0)
            make_request
            expect(response.status).to eq(201)
            parsed_response = JSON.parse(response.body)
            expect(parsed_response).to (eq({}))
            expect(RawTime.all.size).to eq(2)
            expect(RawTime.all.map(&:bib_number)).to all eq(bib_number)
            expect(RawTime.all.map(&:bitkey)).to eq([in_bitkey, out_bitkey])
            expect(RawTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
            expect(RawTime.all.map(&:event_group_id)).to all eq(event_group.id)
          end
        end
      end

      context 'when there is a duplicate raw_time in the database' do
        before do
          create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, bitkey: in_bitkey, absolute_time: absolute_time_in, with_pacer: true, stopped_here: false, source: source)
        end

        context 'when unique_key is set' do
          via_login_and_jwt do
            let(:unique_key) { %w(absoluteTime splitName bitkey bibNumber source withPacer stoppedHere) }

            it 'saves the non-duplicate raw_time to the database and updates the existing raw_time' do
              expect(RawTime.count).to eq(1)
              make_request
              expect(response.status).to eq(201)
              expect(RawTime.count).to eq(2)
            end
          end
        end

        context 'when unique_key is not set' do
          via_login_and_jwt do
            let(:unique_key) { nil }

            it 'saves both raw_times to the database' do
              expect(RawTime.count).to eq(1)
              make_request
              expect(response.status).to eq(201)
              expect(RawTime.count).to eq(3)
            end
          end
        end
      end

      context 'when there is a duplicate split_time in the database' do
        via_login_and_jwt do
          let(:split) { event.splits.first }
          let(:day_and_time) { time_zone.parse(absolute_time_in) }
          let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: in_bitkey, day_and_time: absolute_time_in, pacer: true, stopped_here: false) }

          it 'saves the raw_times to the database and matches the duplicate raw_time with the existing split_time' do
            expect(SplitTime.count).to eq(1)
            expect(RawTime.count).to eq(0)
            make_request
            expect(response.status).to eq(201)
            expect(SplitTime.count).to eq(1)
            expect(RawTime.count).to eq(2)
            expect(RawTime.all.map(&:split_time_id)).to match_array([split_time.id, nil])
          end
        end
      end

      context 'when there is a non-duplicate split_time in the database' do
        via_login_and_jwt do
          let(:effort) { create(:effort, event: event) }
          let(:split) { event.splits.first }
          let(:day_and_time) { time_zone.parse(absolute_time_in) }
          let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: in_bitkey, day_and_time: absolute_time_in + 2.minutes, pacer: true, stopped_here: false) }

          it 'saves the raw_times to the database and does not match any raw_time with the existing split_time' do
            expect(SplitTime.count).to eq(1)
            expect(RawTime.count).to eq(0)
            make_request
            expect(response.status).to eq(201)
            expect(SplitTime.count).to eq(1)
            expect(RawTime.count).to eq(2)
            expect(RawTime.all.map(&:split_time_id)).to all be_nil
          end
        end
      end

      context 'when push notifications are permitted' do
        via_login_and_jwt do
          let(:event_group) { create(:event_group, available_live: true, concealed: false) }

          it 'sends a push notification that includes the count of available raw times' do
            expect(event.permit_notifications?).to be(true)
            allow(Pusher).to receive(:trigger)
            make_request
            expected_args = ["raw-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 2, unmatched: 2}]
            expect(Pusher).to have_received(:trigger).with(*expected_args)
          end
        end
      end

      context 'when event_group.permit_notifications? is true and auto_live_times is true' do
        via_login_and_jwt do
          let!(:event_group) { create(:event_group, concealed: false, available_live: true, auto_live_times: true) }
          let!(:effort) { create(:effort, event: event, bib_number: 101, person: person) }
          let!(:person) { create(:person) }
          let(:data) { [
              {type: 'raw_time',
               attributes: {bibNumber: '101', splitName: splits.second.base_name, bitkey: in_bitkey, absoluteTime: absolute_time_in,
                            withPacer: true, stoppedHere: false, source: source}},
              {type: 'raw_time',
               attributes: {bibNumber: '101', splitName: splits.second.base_name, bitkey: out_bitkey, absoluteTime: absolute_time_out,
                            withPacer: true, stoppedHere: true, source: source}}
          ] }

          it 'creates new split_times matching the raw_times' do
            make_request
            expect(response.status).to eq(201)
            expect(RawTime.all.size).to eq(2)
            expect(SplitTime.all.size).to eq(2)
            expect(SplitTime.all.map(&:day_and_time)).to match_array([absolute_time_in, absolute_time_out])
            expect(SplitTime.all.map(&:bitkey)).to match_array([in_bitkey, out_bitkey])

            expect(RawTime.all.pluck(:split_time_id)).to match_array(SplitTime.all.ids)
          end

          it 'sends a message to NotifyFollowersJob with relevant person and split_time data' do
            allow(NotifyFollowersJob).to receive(:perform_later) do |args|
              args[:split_time_ids].sort!
            end

            make_request
            split_time_ids = SplitTime.all.ids
            person_id = SplitTime.first.effort.person_id

            expect(NotifyFollowersJob).to have_received(:perform_later).with(person_id: person_id, split_time_ids: split_time_ids.sort)
          end

          it 'sends messages to Interactors::SetEffortStatus with the efforts associated with the modified split_times' do
            allow(Interactors::SetEffortStatus).to receive(:perform).and_return(Interactors::Response.new([], '', {}))
            make_request

            expect(Interactors::SetEffortStatus).to have_received(:perform)
          end
        end
      end
    end
  end

  describe '#pull_raw_times' do
    subject(:make_request) { patch :pull_raw_times, params: request_params }
    let(:request_params) { {id: event_group.id} }

    let!(:event_group) { create(:event_group, available_live: true) }
    let!(:course) { create(:course) }
    let!(:event) { create(:event, event_group: event_group, course: course, home_time_zone: 'Arizona') }
    let!(:effort_1) { create(:effort, event: event, bib_number: 111) }
    let!(:effort_2) { create(:effort, event: event, bib_number: 112) }
    let!(:start_split) { create(:split, :start, course: course, base_name: 'Start') }
    let!(:aid_split) { create(:split, course: course, base_name: 'Aid 1') }
    let!(:finish_split) { create(:split, :finish, course: course, base_name: 'Finish') }
    let!(:effort_1_split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: start_split, bitkey: in_bitkey, time_from_start: 0) }
    let!(:effort_1_split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: aid_split, bitkey: in_bitkey, time_from_start: 5000) }

    let(:current_user) { controller.current_user }

    before do
      event.splits << [start_split, aid_split, finish_split]
      allow(Pusher).to receive(:trigger)
    end

    context 'when unpulled raw_times are available' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, effort: effort_1, bib_number: '111', absolute_time: '2017-07-01 11:22:33-0700', split_name: 'Finish') }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, effort: effort_2, bib_number: '112', absolute_time: '2017-07-01 12:23:34-0700', split_name: 'Finish') }

      via_login_and_jwt do
        it 'marks the raw_times as having been pulled and returns raw_time_rows with entered_times' do
          response = make_request
          expect(RawTime.all.pluck(:pulled_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig('data', 'rawTimeRows')

          expect(time_rows.size).to eq(2)
          expect(time_rows.map { |row| row['rawTimes'].size }).to match_array([1, 1])
          expect(time_rows.map { |row| row['rawTimes'].first['splitName'] }).to all eq(finish_split.base_name)
          expect(time_rows.map { |row| row['rawTimes'].first['bibNumber'] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
          expect(time_rows.map { |row| row['rawTimes'].first['enteredTime'] }).to match_array(%w(11:22:33 12:23:34))
        end
      end
    end

    context 'when unpulled raw_times have in and out times that can be paired' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '112', absolute_time: '2017-07-01 11:22:33', split_name: 'Aid 1', sub_split_kind: 'in') }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '112', absolute_time: '2017-07-01 12:23:34', split_name: 'Aid 1', sub_split_kind: 'out') }

      via_login_and_jwt do
        it 'marks the raw_times as having been pulled and returns them in a single raw_time_row' do
          response = make_request
          expect(RawTime.all.pluck(:pulled_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig('data', 'rawTimeRows')

          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row['rawTimes'].size).to eq(2)
          expect(time_row['rawTimes'].map { |rt| rt['splitName'] }).to match_array([aid_split.base_name, aid_split.base_name])
          expect(time_row['rawTimes'].map { |rt| rt['bibNumber'] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context 'when unpulled raw_times do not match existing bib numbers' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '999', absolute_time: '2017-07-01 11:22:33', split_name: 'Aid 1', sub_split_kind: 'in') }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '999', absolute_time: '2017-07-01 12:23:34', split_name: 'Aid 1', sub_split_kind: 'out') }

      via_login_and_jwt do
        it 'marks the raw_times as having been pulled and returns a raw_time_row with event and effort attributes set to nil' do
          response = make_request
          expect(RawTime.all.pluck(:pulled_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig('data', 'rawTimeRows')
          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row['rawTimes'].size).to eq(2)
          expect(time_row['rawTimes'].map { |rt| rt['splitName'] }).to match_array([aid_split.base_name, aid_split.base_name])
          expect(time_row['rawTimes'].map { |rt| rt['bibNumber'] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context 'when unpulled raw_times do not match existing split names' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '111', absolute_time: '2017-07-01 11:22:33', split_name: 'Nonexistent', sub_split_kind: 'in') }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '111', absolute_time: '2017-07-01 12:23:34', split_name: 'Nonexistent', sub_split_kind: 'out') }

      via_login_and_jwt do
        it 'marks the raw_times as having been pulled and returns a raw_time_row with event and effort attributes loaded' do
          response = make_request
          expect(RawTime.all.pluck(:pulled_by)).to all eq(current_user.id)

          result = JSON.parse(response.body)
          time_rows = result.dig('data', 'rawTimeRows')
          expect(time_rows.size).to eq(1)

          time_row = time_rows.first
          expect(time_row['rawTimes'].size).to eq(2)
          expect(time_row['rawTimes'].map { |rt| rt['splitName'] }).to match_array([raw_time_1.split_name, raw_time_2.split_name])
          expect(time_row['rawTimes'].map { |rt| rt['bibNumber'] }).to match_array([raw_time_1.bib_number, raw_time_2.bib_number])
        end
      end
    end

    context 'when no unpulled raw_times are available' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '111', absolute_time: '2017-07-01 11:22:33', split_name: 'Finish', pulled_by: 1, pulled_at: Time.now) }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '112', absolute_time: '2017-07-01 12:23:34', split_name: 'Finish', pulled_by: 1, pulled_at: Time.now) }

      via_login_and_jwt do
        it 'returns an empty array' do
          response = make_request
          result = JSON.parse(response.body)

          expect(result.dig('data', 'rawTimeRows')).to eq([])
        end
      end
    end
  end

  describe '#enrich_raw_time_row' do
    subject(:make_request) { get :enrich_raw_time_row, params: request_params }
    let(:request_params) { {id: event_group.id, data: {raw_time_row: raw_time_row}} }
    let(:raw_time_row) { {raw_times: raw_time_attributes} }
    let(:raw_time_attributes) { {0 => raw_time_attributes_1, 1 => raw_time_attributes_2}.compact }
    let(:errors) { [] }

    let!(:event_group) { create(:event_group, available_live: true) }
    let!(:course) { create(:course) }
    let!(:event_1) { create(:event, event_group: event_group, course: course) }
    let!(:event_2) { create(:event, event_group: event_group, course: course) }

    let!(:start_split) { create(:split, :start, course: course, base_name: 'Start') }
    let!(:aid_split) { create(:split, course: course, base_name: 'Aid 1') }
    let!(:finish_split) { create(:split, :finish, course: course, base_name: 'Finish') }
    let(:splits) { [start_split, aid_split, finish_split] }

    let!(:effort_1) { create(:effort, event: event_1, bib_number: 111) }
    let!(:effort_2) { create(:effort, event: event_2, bib_number: 112) }

    let!(:effort_1_split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: start_split, bitkey: in_bitkey, time_from_start: 0) }
    let!(:effort_1_split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: aid_split, bitkey: in_bitkey, time_from_start: 5000) }
    let!(:effort_1_split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: aid_split, bitkey: out_bitkey, time_from_start: 6000) }
    let!(:effort_1_split_time_4) { create(:split_time, effort: effort_1, lap: 1, split: finish_split, bitkey: in_bitkey, time_from_start: 10000) }
    let!(:effort_2_split_time_1) { create(:split_time, effort: effort_2, lap: 1, split: start_split, bitkey: in_bitkey, time_from_start: 0) }
    let!(:effort_2_split_time_2) { create(:split_time, effort: effort_2, lap: 1, split: aid_split, bitkey: in_bitkey, time_from_start: 7000) }

    before do
      event_1.splits << splits
      event_2.splits << splits
    end

    context 'when a valid raw_time_row is submitted' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '11:22:33', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '11:23:34', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'adds split_time_exists and correctly interprets all attributes, returning no errors' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to eq([])

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(111 111))
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1', 'Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([true, true])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end

    context 'when only one raw_time is included' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '11:22:33', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { nil }

      via_login_and_jwt do
        it 'adds split_time_exists and data_status' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to eq([])

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(1)
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(111))
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1])
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(['In'])
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([true])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true])
        end
      end
    end

    context 'when only one existing time is present' do
      let(:raw_time_attributes_1) { {bib_number: '112', entered_time: '11:22:33', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '112', entered_time: '11:23:34', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'correctly computes split_time_exists' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to eq([])

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(112 112))
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1', 'Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([true, false])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end

    context 'when a an entered_time is invalid' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '11:mm:ss', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '11:23:34', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'returns the raw_time without a military_time attribute' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to eq([])

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(111 111))
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1', 'Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq([nil, '11:23:34'])
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:mm:ss 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([true, true])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end

    context 'when the bib number is not found' do
      let(:raw_time_attributes_1) { {bib_number: '999', entered_time: '11:22:33', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '999', entered_time: '11:23:34', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'returns data without adding split_time_exists' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to include('missing effort')

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(999 999))
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1', 'Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end

    context 'when the split name is not found' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '11:22:33', split_name: 'Nonexistent', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '11:23:34', split_name: 'Nonexistent', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'returns data without adding split_time_exists and adds a descriptive error' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to include('invalid split name')

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(111 111))
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(%w(Nonexistent Nonexistent))
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end

    context 'when the bib number contains an asterisk' do
      let(:raw_time_attributes_1) { {bib_number: '9*9', entered_time: '11:22:33', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'in'} }
      let(:raw_time_attributes_2) { {bib_number: '9*9', entered_time: '11:23:34', split_name: 'Aid 1', with_pacer: 'true', sub_split_kind: 'out', stopped_here: 'true'} }

      via_login_and_jwt do
        it 'returns data without adding split_time_exists' do
          response = make_request
          result = JSON.parse(response.body)
          raw_time_row = result.dig('data', 'rawTimeRow')

          expect(raw_time_row['errors']).to include('missing effort')

          raw_times = raw_time_row['rawTimes']
          expect(raw_times.size).to eq(2)
          expect(raw_times.map { |rt| rt['lap'] }).to eq([1, 1])
          expect(raw_times.map { |rt| rt['bibNumber'] }).to eq(%w(9*9 9*9))
          expect(raw_times.map { |rt| rt['splitName'] }).to eq(['Aid 1', 'Aid 1'])
          expect(raw_times.map { |rt| rt['subSplitKind'] }).to eq(%w(In Out))
          expect(raw_times.map { |rt| rt['militaryTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['enteredTime'] }).to eq(%w(11:22:33 11:23:34))
          expect(raw_times.map { |rt| rt['splitTimeExists'] }).to eq([nil, nil])
          expect(raw_times.map { |rt| rt['stoppedHere'] }).to eq([false, true])
          expect(raw_times.map { |rt| rt['withPacer'] }).to eq([true, true])
        end
      end
    end
  end

  describe '#submit_raw_time_rows' do
    subject(:make_request) { post :submit_raw_time_rows, params: request_params }
    let(:request_params) { {id: event_group.id, data: raw_time_data, force_submit: force_submit} }
    let(:raw_time_data) { {"0" => {"raw_time_row" => {"raw_times" => {"0" => raw_time_attributes_1, "1" => raw_time_attributes_2}}}} }

    let!(:event_group) { create(:event_group, available_live: true) }
    let!(:course_1) { create(:course) }
    let!(:course_2) { create(:course) }
    let!(:event_1) { create(:event, event_group: event_group, course: course_1, home_time_zone: 'Mountain Time (US & Canada)', start_time_local: '2018-09-30 08:00') }
    let!(:event_2) { create(:event, event_group: event_group, course: course_2, home_time_zone: 'Mountain Time (US & Canada)', start_time_local: '2018-09-30 08:00') }
    let(:start_time_1) { event_1.start_time_local }
    let(:start_time_2) { event_2.start_time_local }

    let!(:course_1_start_split) { create(:split, :start, course: course_1, base_name: 'Start') }
    let!(:course_1_aid_1_split) { create(:split, course: course_1, base_name: 'Aid 1', distance_from_start: 10000) }
    let!(:course_1_finish_split) { create(:split, :finish, course: course_1, base_name: 'Finish', distance_from_start: 20000) }
    let(:course_1_splits) { [course_1_start_split, course_1_aid_1_split, course_1_finish_split] }

    let!(:course_2_start_split) { create(:split, :start, course: course_2, base_name: 'Start') }
    let!(:course_2_aid_1_split) { create(:split, course: course_2, base_name: 'Aid 1', distance_from_start: 10000) }
    let!(:course_2_aid_2_split) { create(:split, course: course_2, base_name: 'Aid 2', distance_from_start: 20000) }
    let!(:course_2_finish_split) { create(:split, :finish, course: course_2, base_name: 'Finish', distance_from_start: 30000) }
    let(:course_2_splits) { [course_2_start_split, course_2_aid_1_split, course_2_aid_2_split, course_2_finish_split] }

    let!(:effort_1) { create(:effort, event: event_1, bib_number: 111) }
    let!(:effort_2) { create(:effort, event: event_2, bib_number: 112) }

    let!(:effort_1_split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: course_1_start_split, bitkey: in_bitkey, absolute_time: start_time_1 + 0) }
    let!(:effort_1_split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: course_1_aid_1_split, bitkey: in_bitkey, absolute_time: start_time_1 + 5000) }
    let!(:effort_1_split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: course_1_aid_1_split, bitkey: out_bitkey, absolute_time: start_time_1 + 6000) }
    let!(:effort_1_split_time_4) { create(:split_time, effort: effort_1, lap: 1, split: course_1_finish_split, bitkey: in_bitkey, absolute_time: start_time_1 + 10000) }
    let!(:effort_2_split_time_1) { create(:split_time, effort: effort_2, lap: 1, split: course_2_start_split, bitkey: in_bitkey, absolute_time: start_time_2 + 0) }
    let!(:effort_2_split_time_2) { create(:split_time, effort: effort_2, lap: 1, split: course_2_aid_1_split, bitkey: in_bitkey, absolute_time: start_time_2 + 7000) }

    before do
      event_1.splits << course_1_splits
      event_2.splits << course_2_splits
      effort_1.reload
    end

    context 'when data is valid and force_submit is true' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '09:00:00', split_name: 'Aid 1', sub_split_kind: 'in', source: 'Live Entry (1)'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '09:05:00', split_name: 'Aid 1', sub_split_kind: 'out', source: 'Live Entry (1)'} }
      let(:force_submit) { 'true' }

      via_login_and_jwt do
        it 'overwrites existing duplicate split_times, creates raw_times, and does not return raw_time_rows' do
          expect(effort_1.split_times.map(&:absolute_time)).to match_array([start_time_1 + 0, start_time_1 + 5000, start_time_1 + 6000, start_time_1 + 10000])
          response = make_request
          expect(response.status).to eq(201)
          result = JSON.parse(response.body)
          expect(result.dig('data', 'rawTimeRows')).to eq([])
          effort_1.reload
          expect(effort_1.split_times.map(&:absolute_time)).to match_array([start_time_1 + 0, start_time_1 + 3600, start_time_1 + 3900, start_time_1 + 10000])
          expect(RawTime.count).to eq(2)
        end
      end
    end

    context 'when data is valid but duplicates exist and force_submit is false' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '09:00:00', split_name: 'Aid 1', sub_split_kind: 'in', source: 'Live Entry (1)'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '09:05:00', split_name: 'Aid 1', sub_split_kind: 'out', source: 'Live Entry (1)'} }
      let(:force_submit) { 'false' }
      let(:expected) { [{'rawTimes' =>
                             [{'id' => nil,
                               'splitName' => 'Aid 1',
                               'bibNumber' => '111',
                               'absoluteTime' => nil,
                               'enteredTime' => '09:00:00',
                               'withPacer' => false,
                               'stoppedHere' => false,
                               'source' => 'Live Entry (1)',
                               'remarks' => nil,
                               'dataStatus' => nil,
                               'lap' => 1,
                               'splitTimeExists' => true,
                               'militaryTime' => '09:00:00',
                               'subSplitKind' => 'In'},
                              {'id' => nil,
                               'splitName' => 'Aid 1',
                               'bibNumber' => '111',
                               'absoluteTime' => nil,
                               'enteredTime' => '09:05:00',
                               'withPacer' => false,
                               'stoppedHere' => false,
                               'source' => 'Live Entry (1)',
                               'remarks' => nil,
                               'dataStatus' => nil,
                               'lap' => 1,
                               'splitTimeExists' => true,
                               'militaryTime' => '09:05:00',
                               'subSplitKind' => 'Out'}],
                         'errors' => ['bad or duplicate time']}] }

      via_login_and_jwt do
        it 'does not overwrite existing duplicate split_times, does not create raw_times, and returns raw_time_rows' do
          expect(effort_1.split_times.map(&:absolute_time)).to match_array([start_time_1 + 0, start_time_1 + 5000, start_time_1 + 6000, start_time_1 + 10000])
          response = make_request
          result = JSON.parse(response.body)
          expect(result.dig('data', 'rawTimeRows')).to eq(expected)
          effort_1.reload
          expect(effort_1.split_times.map(&:absolute_time)).to match_array([start_time_1 + 0, start_time_1 + 5000, start_time_1 + 6000, start_time_1 + 10000])
          expect(RawTime.count).to eq(0)
        end
      end
    end

    context 'when the bib number does not belong at the split' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '09:00:00', split_name: 'Aid 2', sub_split_kind: 'in', source: 'Live Entry (1)'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '09:05:00', split_name: 'Aid 2', sub_split_kind: 'out', source: 'Live Entry (1)'} }
      let(:force_submit) { true }

      via_login_and_jwt do
        it 'does not create raw_times or split_times and returns raw_time_rows with descriptive errors' do
          expect(SplitTime.count).to eq(6)
          response = make_request
          result = JSON.parse(response.body)
          expect(RawTime.count).to eq(0)
          expect(SplitTime.count).to eq(6)
          expect(result.dig('data', 'rawTimeRows').first['rawTimes'].size).to eq(2)
          expect(result.dig('data', 'rawTimeRows').first['errors']).to include('invalid split name')
        end
      end
    end

    context 'when the bib number is invalid' do
      let(:raw_time_attributes_1) { {bib_number: '999', entered_time: '09:00:00', split_name: 'Aid 2', sub_split_kind: 'in', source: 'Live Entry (1)'} }
      let(:raw_time_attributes_2) { {bib_number: '999', entered_time: '09:05:00', split_name: 'Aid 2', sub_split_kind: 'out', source: 'Live Entry (1)'} }
      let(:force_submit) { true }

      via_login_and_jwt do
        it 'does not create raw_times or split_times and returns raw_time_rows with a descriptive error' do
          expect(SplitTime.count).to eq(6)
          response = make_request
          result = JSON.parse(response.body)
          expect(RawTime.count).to eq(0)
          expect(SplitTime.count).to eq(6)
          expect(result.dig('data', 'rawTimeRows').first['rawTimes'].size).to eq(2)
          expect(result.dig('data', 'rawTimeRows').first['errors']).to include('missing effort')
        end
      end
    end

    context 'when the split_name is invalid' do
      let(:raw_time_attributes_1) { {bib_number: '111', entered_time: '09:00:00', split_name: 'Nonexistent', sub_split_kind: 'in', source: 'Live Entry (1)'} }
      let(:raw_time_attributes_2) { {bib_number: '111', entered_time: '09:05:00', split_name: 'Nonexistent', sub_split_kind: 'out', source: 'Live Entry (1)'} }
      let(:force_submit) { true }

      via_login_and_jwt do
        it 'does not create raw_times or split_times and returns raw_time_rows with a descriptive error' do
          expect(SplitTime.count).to eq(6)
          response = make_request
          result = JSON.parse(response.body)
          expect(RawTime.count).to eq(0)
          expect(SplitTime.count).to eq(6)
          expect(result.dig('data', 'rawTimeRows').first['rawTimes'].size).to eq(2)
          expect(result.dig('data', 'rawTimeRows').first['errors']).to include('invalid split name')
        end
      end
    end
  end

  describe '#trigger_raw_times_push' do
    subject(:make_request) { get :trigger_raw_times_push, params: request_params }
    let(:course) { create(:course) }
    let(:split) { create(:split, course_id: course.id) }
    let(:event) { create(:event, event_group: event_group, course: course) }
    let(:request_params) { {id: event_group.id} }
    before do
      event.splits << split
      create_list(:raw_time, 3, event_group: event_group, split_name: split.base_name)
    end

    via_login_and_jwt do
      it 'sends a push notification that includes the count of available times' do
        allow(Pusher).to receive(:trigger)
        make_request
        expected_rt_args = ["raw-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 3, unmatched: 3}]
        expect(Pusher).to have_received(:trigger).with(*expected_rt_args)
      end
    end
  end
end
