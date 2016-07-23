require 'rails_helper'

RSpec.describe ParticipantsController, :type => :controller do
  describe "anonymous user" do
    before :each do
      # This simulates an anonymous user
      login_with nil
      @participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
    end

    it "on call to index should direct the user to a participant search screen" do
      get :index
      expect(response).to render_template(:index)
    end

    it "on call to show should direct the user to the participant show view" do
      get :show, id: @participant1
      expect(response).to render_template(:show)
    end

    it "on call to new should be redirected to signin" do
      get :new
      expect(response).to redirect_to(new_user_session_path)
    end

    it "on call to edit should be redirected to signin" do
      get :edit, id: @participant1
      expect(response).to redirect_to(new_user_session_path)
    end

    it "on call to destroy should be redirected to signin" do
      delete :destroy, id: @participant1
      expect(response).to redirect_to(new_user_session_path)
    end


  end

  describe "registered user" do

    before :each do
      @participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      user = create(:user)
      login_with user
      @participant2 = Participant.create!(first_name: 'Jane', last_name: 'Eyre', gender: 'female', created_by: user.id)
    end

    it "should let a user see all the participants" do
      get :index
      expect(response).to render_template(:index)
    end

    it "on call to show should direct the user to the participant show view" do
      get :show, id: @participant1
      expect(response).to render_template(:show)
    end

    it "on call to new should deny access and redirect to root" do
      get :new
      expect(response).to redirect_to(root_path)
    end

    it "on call to edit for a participant created by the user, should direct the user to the edit participant page" do
      get :edit, id: @participant2
      expect(response).to render_template(:edit)
    end

    it "on call to edit for a participant not created by the user, should redirect to root" do
      get :edit, id: @participant1
      expect(response).to redirect_to(root_path)
    end

    it "on call to destroy should redirect to root" do
      delete :destroy, id: @participant1
      expect(response).to redirect_to(root_path)
    end

  end

end