require 'rails_helper'

describe Api::V1::LiveTimesController do
  login_admin
  before do
    event.splits << split
  end

  let(:live_time) { FactoryGirl.create(:live_time, event: event, split: split) }
  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:split) { FactoryGirl.create(:split, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#index' do
    before do
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 101, absolute_time: '10:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 102, absolute_time: '11:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 103, absolute_time: '10:30:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 103, absolute_time: '16:00:00', source: 'ost-test')
      create(:live_time, event: event, split: split, bitkey: 1, bib_number: 101, absolute_time: '16:00:00', source: 'ost-test')
    end

    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns each live_time' do
      get :index
      expect(response.status).to eq(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].size).to eq(5)
      expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(LiveTime.all.map(&:id))
    end

    it 'sorts properly in ascending order based on a provided sort parameter' do
      expected = [101, 101, 102, 103, 103]
      get :index, sort: 'bib_number'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end

    it 'sorts properly in descending order based on a provided sort parameter with a minus sign' do
      expected = [103, 103, 102, 101, 101]
      get :index, sort: '-bibNumber'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end

    it 'sorts properly on multiple fields' do
      expected = [101, 103, 102, 103, 101]
      get :index, sort: '-absolute_time,bib_number'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].map { |item| item.dig('attributes', 'bibNumber') }).to eq(expected)
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: live_time
      expect(response.status).to eq(200)
    end

    it 'returns data of a single live_time' do
      get :show, id: live_time
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(live_time.id)
    end

    it 'returns an error if the live_time does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    let(:attributes) { {event_id: event.id, split_id: split.id, bitkey: 1, bib_number: '101',
                        absolute_time: '08:00:00', source: 'ost-test', batch: '1'} }

    it 'returns a successful json response' do
      post :create, data: {type: 'live_times', attributes: attributes}
      expect(response.body).to be_jsonapi_response_for('live_times')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a live_time record' do
      expect(LiveTime.all.count).to eq(0)
      post :create, data: {type: 'live_times', attributes: attributes}
      expect(LiveTime.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:updated_attributes) { {bib_number: 0} }

    it 'returns a successful json response' do
      put :update, id: live_time, data: {type: 'live_times', attributes: updated_attributes}
      expect(response.body).to be_jsonapi_response_for('live_times')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: live_time, data: {type: 'live_times', attributes: updated_attributes}
      live_time.reload
      expect(live_time.bib_number).to eq(updated_attributes[:bib_number])
    end

    it 'returns an error if the live_time does not exist' do
      put :update, id: 0, data: {type: 'live_times', attributes: updated_attributes}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: live_time
      expect(response.status).to eq(200)
    end

    it 'destroys the live_time record' do
      test_live_time = live_time
      expect(LiveTime.all.count).to eq(1)
      delete :destroy, id: test_live_time
      expect(LiveTime.all.count).to eq(0)
    end

    it 'returns an error if the live_time does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['errors']).to include(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#pull' do
    context 'when unpulled live_times exist for the given event' do
      let!(:unpulled_live_times) { create_list(:live_time, 4, event: event, split: split) }
      let!(:pulled_live_time) { create(:live_time, event: event, split: split, pulled_by: 1, pulled_at: Time.current) }

      it 'returns a successful json response' do
        patch :pull, staging_id: event.id
        expect(response.status).to eq(200)
      end

      it 'selects unpulled live_times for an event, marks them as pulled, and returns them' do
        expect(LiveTime.where(pulled_by: nil).size).to eq(4)
        patch :pull, staging_id: event.id
        expect(LiveTime.where(pulled_by: nil).size).to eq(0)
        expect(LiveTime.where(pulled_by: 1).size).to eq(1)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(4)
        expect(parsed_response['data'].map { |record| record['id'].to_i }.sort)
            .to eq(unpulled_live_times.map(&:id).sort)
      end
    end

    context 'when no unpulled live_times exist for the given event' do
      before do
        other_event.splits << split
      end

      let(:other_event) { create(:event, course: course) }
      let!(:unpulled_live_times) { create_list(:live_time, 4, event: other_event, split: split) }

      it 'returns a successful json response with an empty data array' do
        patch :pull, staging_id: event.id
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data']).to eq([])
      end
    end
  end
end
