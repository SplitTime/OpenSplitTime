require 'rails_helper'

describe Api::V1::CoursesController do
  login_admin

  let(:course) { FactoryGirl.create(:course) }

  describe '#index' do
    it 'returns a successful 200 response' do
      get :index
      expect(response).to be_success
    end

    it 'returns each course that the current_user is authorized to edit' do
      FactoryGirl.create_list(:course, 3)
      get :index
      parsed_response = JSON.parse(response.body)
      expect(parsed_response.size).to eq(3)
      expect(parsed_response.map { |item| item['id'] }).to eq(Course.all.map(&:id))
      expect(response).to be_success
    end
  end

  describe '#show' do
    it 'returns a successful 200 response' do
      get :show, id: course
      expect(response).to be_success
    end

    it 'returns data of a single course' do
      get :show, id: course
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id'].to_i).to eq(course.id)
    end

    it 'returns an error if the course does not exist' do
      get :show, id: 0
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#create' do
    it 'returns a successful json response' do
      post :create, course: {name: 'Test Course'}
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['id']).not_to be_nil
      expect(response).to be_success
    end

    it 'creates a course record' do
      expect(Course.all.count).to eq(0)
      post :create, course: {name: 'Test Course'}
      expect(Course.all.count).to eq(1)
    end
  end

  describe '#update' do
    let(:attributes) { {name: 'Updated Course Name'} }

    it 'returns a successful json response' do
      put :update, id: course, course: attributes
      expect(response).to be_success
    end

    it 'updates the specified fields' do
      put :update, id: course, course: attributes
      course.reload
      expect(course.name).to eq(attributes[:name])
    end

    it 'returns an error if the course does not exist' do
      put :update, id: 0, course: attributes
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['message']).to match(/not found/)
      expect(response).to be_not_found
    end
  end

  describe '#destroy' do
    it 'returns a successful json response' do
      delete :destroy, id: course
      expect(response).to be_success
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
      expect(response).to be_not_found
    end
  end
end
