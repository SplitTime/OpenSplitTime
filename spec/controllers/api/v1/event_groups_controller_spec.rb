require 'rails_helper'

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

          let(:event_1_split_1) { create(:start_split, course: course_1, base_name: 'Start', latitude: 40, longitude: -105) }
          let(:event_1_split_2) { create(:split, course: course_1, base_name: 'Aid 1', latitude: 41, longitude: -106) }
          let(:event_1_split_3) { create(:split, course: course_1, base_name: 'Aid 2', latitude: 42, longitude: -107) }
          let(:event_1_split_4) { create(:finish_split, course: course_1, base_name: 'Finish', latitude: 40, longitude: -105) }
          let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }

          let(:event_2_split_1) { create(:start_split, course: course_2, base_name: 'Start', latitude: 40, longitude: -105) }
          let(:event_2_split_2) { create(:split, course: course_2, base_name: 'Aid 2', latitude: 42, longitude: -107) }
          let(:event_2_split_3) { create(:finish_split, course: course_2, base_name: 'Finish', latitude: 40, longitude: -105) }
          let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

          let(:event_1_id) { event_1.id.to_s }
          let(:event_2_id) { event_2.id.to_s }

          let(:expected) {
            [{'title' => 'Start/Finish',
              'entries' =>
                  [{'eventSplitIds' => {event_2_id => event_2_split_1.id,
                                        event_1_id => event_1_split_1.id},
                    'subSplitKind' => 'in',
                    'label' => 'Start',
                    'splitName' => 'start',
                    'displaySplitName' => 'Start'},
                   {'eventSplitIds' => {event_2_id => event_2_split_3.id,
                                        event_1_id => event_1_split_4.id},
                    'subSplitKind' => 'in',
                    'label' => 'Finish',
                    'splitName' => 'finish',
                    'displaySplitName' => 'Finish'}]},
             {'title' => 'Aid 1',
              'entries' =>
                  [{'eventSplitIds' => {event_1_id => event_1_split_2.id},
                    'subSplitKind' => 'in',
                    'label' => 'Aid 1 In',
                    'splitName' => 'aid-1',
                    'displaySplitName' => 'Aid 1'},
                   {'eventSplitIds' => {event_1_id => event_1_split_2.id},
                    'subSplitKind' => 'out',
                    'label' => 'Aid 1 Out',
                    'splitName' => 'aid-1',
                    'displaySplitName' => 'Aid 1'}]},
             {'title' => 'Aid 2',
              'entries' =>
                  [{'eventSplitIds' => {event_2_id => event_2_split_2.id,
                                        event_1_id => event_1_split_3.id},
                    'subSplitKind' => 'in',
                    'label' => 'Aid 2 In',
                    'splitName' => 'aid-2',
                    'displaySplitName' => 'Aid 2'},
                   {'eventSplitIds' => {event_2_id => event_2_split_2.id,
                                        event_1_id => event_1_split_3.id},
                    'subSplitKind' => 'out',
                    'label' => 'Aid 2 Out',
                    'splitName' => 'aid-2',
                    'displaySplitName' => 'Aid 2'}]}
            ]
          }

          before do
            event_1.splits << event_1_splits
            event_2.splits << event_2_splits
          end

          it 'includes a combinedSplitAttributes key containing information mapping events to splits' do
            make_request
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['data']['attributes']['combinedSplitAttributes']).to eq(expected)
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
    let(:event) { create(:event, start_time_in_home_zone: '2016-07-01 06:00:00', event_group: event_group, course: course, laps_required: 1) }
    let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
    let(:absolute_time_in) { time_zone.parse('2016-07-01 10:45:45') }
    let(:absolute_time_out) { time_zone.parse('2016-07-01 10:50:50') }
    let(:effort) { create(:effort, event: event) }
    let(:bib_number) { effort.bib_number.to_s }
    let(:unique_key) { nil }

    via_login_and_jwt do
      context 'when provided with an array of raw_time hashes and data_format: :jsonapi_batch' do
        let(:split_name) { splits.first.name }
        let(:request_params) { {id: event_group.id, data_format: 'jsonapi_batch', data: data, unique_key: unique_key} }
        let(:data) { [
            {type: 'raw_time',
             attributes: {bibNumber: bib_number, splitName: split_name, subSplitKind: 'in', absoluteTime: absolute_time_in,
                          withPacer: 'true', stoppedHere: 'false', source: source}},
            {type: 'raw_time',
             attributes: {bibNumber: bib_number, splitName: split_name, subSplitKind: 'out', absoluteTime: absolute_time_out,
                          withPacer: 'true', stoppedHere: 'true', source: source}}
        ] }
        let(:source) { 'ost-remote-1234' }

        it 'creates raw_times' do
          expect(RawTime.all.size).to eq(0)
          make_request
          expect(response.status).to eq(201)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |record| record['type'] }).to all (eq('rawTimes'))
          expect(RawTime.all.size).to eq(2)
          expect(RawTime.all.map(&:bib_number)).to all eq(bib_number)
          expect(RawTime.all.map(&:bitkey)).to eq([1, 64])
          expect(RawTime.all.map(&:absolute_time)).to eq([absolute_time_in, absolute_time_out])
          expect(RawTime.all.map(&:event_group_id)).to all eq(event_group.id)
        end

        context 'when there is a duplicate raw_time in the database' do
          before do
            create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, bitkey: 1, absolute_time: absolute_time_in, with_pacer: true, stopped_here: false, source: source)
          end

          context 'when unique_key is set' do
            let(:unique_key) { %w(absoluteTime splitName bitkey bibNumber source withPacer stoppedHere) }

            it 'saves the non-duplicate raw_time to the database and updates the existing raw_time' do
              expect(RawTime.count).to eq(1)
              make_request
              expect(response.status).to eq(201)
              expect(RawTime.count).to eq(2)
            end
          end

          context 'when unique_key is not set' do
            let(:unique_key) { nil }

            it 'returns the duplicate raw_time and an error' do
              expect(RawTime.count).to eq(1)
              make_request
              expect(response.status).to eq(422)
              expect(RawTime.count).to eq(1)
            end
          end
        end

        xcontext 'when there is a duplicate split_time in the database' do
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

        xcontext 'when there is a non-duplicate split_time in the database' do
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

        xcontext 'when the push notifications are permitted' do
          let(:event_group) { create(:event_group, available_live: true) }

          it 'sends a push notification that includes the count of available times' do
            expect(event.permit_notifications?).to be(true)
            allow(Pusher).to receive(:trigger)
            make_request
            expected_args = ["live-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 2, unmatched: 2}]
            expect(Pusher).to have_received(:trigger).with(*expected_args)
          end
        end

        xcontext 'when the event_group is visible and available live and auto_live_times is true' do
          let!(:event_group) { create(:event_group, concealed: false, available_live: true, auto_live_times: true) }
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
