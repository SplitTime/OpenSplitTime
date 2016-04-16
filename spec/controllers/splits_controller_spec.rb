require 'rails_helper'

RSpec.describe SplitsController, :type => :controller do
  describe "anonymous user" do
    before :each do
      # This simulates an anonymous user
      login_with nil
    end

    it "should let anonymous user see a list of splits" do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "registered user" do
    before :each do
      DatabaseCleaner.clean
      login_with create(:user)
      @course = Course.create!(name: 'Test Course')
      @location1 = Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
      @location2 = Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    end

    it "should let a user see a list of splits" do
      get :index
      expect(response).to render_template(:index)
    end

    it "should let a user see a specific split" do
      split1 = Split.create!(course_id: @course.id, location_id: 1, name: 'Aid Station In', distance_from_start: 7000, sub_order: 1, kind: 2)
      get :show, id: split1.id
      expect(response).to render_template(:show, id: split1.id)
    end

    it "should automatically set sub_orders of splits containing 'in' and 'out' in their names to '0' and '1' respectively" do
      Split.create!(course_id: @course.id, name: 'Aid Station In', distance_from_start: 7000, sub_order: 1, kind: 'waypoint')
      split2_attributes = {course_id: @course.id, name: 'Aid Station Out', distance_from_start: 7000, kind: 'waypoint'}
      post :create, split: split2_attributes
      expect(Split.count).to eq(2)
      expect(Split.where(name: 'Aid Station In').first.sub_order).to eq(0)
      expect(Split.where(name: 'Aid Station Out').first.sub_order).to eq(1)
    end

    it "should automatically increment sub_order of newly created split within waypoint group" do
      Split.create!(course_id: @course.id, name: 'Transition Started', distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      split2_attributes = {course_id: @course.id, name: 'Transition Finished', distance_from_start: 7000, kind: 'waypoint'}
      post :create, split: split2_attributes
      expect(Split.count).to eq(2)
      expect(Split.where(name: 'Transition Finished').first.sub_order).to eq(1)
    end

    it "when created with a location, should automatically reset locations of splits in waypoint group" do
      Split.create!(course_id: @course.id, name: 'Aid Station In', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      Split.create!(course_id: @course.id, name: 'Aid Station Change', location_id: nil, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      split3_attributes = {course_id: @course.id, name: 'Aid Station Out', location_id: @location2.id, distance_from_start: 7000, sub_order: 1, kind: 'waypoint'}
      post :create, split: split3_attributes
      expect(Split.count).to eq(3)
      expect(Split.where(name: 'Aid Station In').first.location_id).to eq(@location2.id)
      expect(Split.where(name: 'Aid Station Change').first.location_id).to eq(@location2.id)
      expect(Split.where(name: 'Aid Station Out').first.location_id).to eq(@location2.id)
    end

    it "when created without a location, should automatically set to location of splits in waypoint group" do
      Split.create!(course_id: @course.id, name: 'Aid Station In', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      Split.create!(course_id: @course.id, name: 'Aid Station Change', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      split3_attributes = {course_id: @course.id, name: 'Aid Station Out', location_id: nil, distance_from_start: 7000, sub_order: 1, kind: 'waypoint'}
      post :create, split: split3_attributes
      expect(Split.count).to eq(3)
      expect(Split.where(name: 'Aid Station In').first.location_id).to eq(@location1.id)
      expect(Split.where(name: 'Aid Station Change').first.location_id).to eq(@location1.id)
      expect(Split.where(name: 'Aid Station Out').first.location_id).to eq(@location1.id)
    end

    it "when location is updated, should automatically update location of splits in waypoint group" do
      Split.create!(course_id: @course.id, name: 'Aid Station In', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      Split.create!(course_id: @course.id, name: 'Aid Station Change', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      split3 = Split.create!(course_id: @course.id, name: 'Aid Station Out', location_id: @location1.id, distance_from_start: 7000, sub_order: 0, kind: 'waypoint')
      split3_attributes = {location_id: @location2.id}
      put :update, id: split3.id, split: split3_attributes
      expect(Split.count).to eq(3)
      expect(Split.where(name: 'Aid Station In').first.location_id).to eq(@location2.id)
      expect(Split.where(name: 'Aid Station Change').first.location_id).to eq(@location2.id)
      expect(Split.where(name: 'Aid Station Out').first.location_id).to eq(@location2.id)
    end
  end
end