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
      login_with create(:user)
      allow(User).to receive(:current).and_return(controller.current_user)
      @course = Course.create!(name: 'Test Course')
      @location1 = Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
      @location2 = Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    end

    it "should let a user see a list of splits" do
      get :index
      expect(response).to render_template(:index)
    end

    it "should let a user see a specific split" do
      split1 = Split.create!(course_id: @course.id, location_id: @location1, base_name: 'Aid Station',
                             distance_from_start: 7000, sub_split_bitmap: 65, kind: 2)
      get :show, id: split1.id
      expect(response).to render_template(:show, id: split1.id)
    end

  end
end