require 'rails_helper'

describe Api::V1::EventsController do
  login_admin

  let(:event) { FactoryGirl.create(:event, course: course) }
  let(:course) { FactoryGirl.create(:course) }

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: event
      expect(response).to be_success
    end

    it 'returns data of a single event' do
      get :show, id: event
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).to eq(event.id)
    end

    it 'returns an error if the event does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response with success message' do
      post :create, event: {course_id: course.id, name: 'Test Event',
                            start_time: '2017-03-01 06:00:00', laps_required: 1}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event created/)
      expect(parsed_response['event']['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates an event record' do
      expect(Event.all.count).to eq(0)
      post :create, event: {course_id: course.id, name: 'Test Event',
                            start_time: '2017-03-01 06:00:00', laps_required: 1}
      expect(Event.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Event Name'} }

    it 'returns a successful json response with success message' do
      put :update, id: event, event: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event updated/)
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: event, event: attributes
      event.reload
      expect(event.name).to eq(attributes[:name])
    end

    it 'returns an error if the event does not exist' do
      put :update, id: 0, event: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response with success message' do
      delete :destroy, id: event
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/event destroyed/)
      expect(response).to be_success
    end

    it 'destroys the event record' do
      test_event = event
      expect(Event.all.count).to eq(1)
      delete :destroy, id: test_event
      expect(Event.all.count).to eq(0)
    end

    it 'returns an error if the event does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end
end