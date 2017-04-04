require 'rails_helper'

describe Api::V1::CoursesController do
  login_admin

  let(:course) { FactoryGirl.create(:course) }

  describe '#index' do
    it 'returns a successful 200 response' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns each course that the current_user is authorized to edit' do
      FactoryGirl.create_list(:course, 3)
      get :index
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].size).to eq(3)
      expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(Course.all.map(&:id))
      expect(response.status).to eq(200)
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: course
      expect(response.status).to eq(200)
    end

    it 'returns data of a single course' do
      get :show, id: course
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(course.id)
      expect(response.body).to be_jsonapi_response_for('courses')
    end

    it 'returns an error if the course does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, data: {type: 'courses', attributes: {name: 'Test Course'} }
      expect(response.body).to be_jsonapi_response_for('courses')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).not_to be_nil
      expect(response.status).to eq(201)
    end

    it 'creates a course record' do
      expect(Course.all.count).to eq(0)
      post :create, data: {type: 'courses', attributes: {name: 'Test Course'} }
      expect(Course.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Course Name'} }

    it 'returns a successful json response' do
      put :update, id: course, data: {type: 'courses', attributes: attributes }
      expect(response.body).to be_jsonapi_response_for('courses')
      expect(response.status).to eq(200)
    end

    it 'updates the specified fields' do
      put :update, id: course, data: {type: 'courses', attributes: attributes }
      course.reload
      expect(course.name).to eq(attributes[:name])
    end

    it 'returns an error if the course does not exist' do
      put :update, id: 0, data: {type: 'courses', attributes: attributes }
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: course
      expect(response.status).to eq(200)
    end

    it 'destroys the course record' do
      test_course = course
      expect(Course.all.count).to eq(1)
      delete :destroy, id: test_course
      expect(Course.all.count).to eq(0)
    end

    it 'returns an error if the course does not exist' do
      delete :destroy, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response.status).to eq(404)
    end
  end
end
