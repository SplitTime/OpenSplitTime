require 'test_helper'

class EffortsControllerTest < ActionController::TestCase
  setup do
    @effort = efforts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:efforts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create effort" do
    assert_difference('Effort.count') do
      post :create, effort: { bib_number: @effort.bib_number, effort_age: @effort.effort_age, effort_city: @effort.effort_city, effort_country: @effort.effort_country, effort_id: @effort.effort_id, effort_state: @effort.effort_state, event_id: @effort.event_id, official_finish: @effort.official_finish, participant_id: @effort.participant_id, start_time: @effort.start_time, wave: @effort.wave }
    end

    assert_redirected_to effort_path(assigns(:effort))
  end

  test "should show effort" do
    get :show, id: @effort
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @effort
    assert_response :success
  end

  test "should update effort" do
    patch :update, id: @effort, effort: { bib_number: @effort.bib_number, effort_age: @effort.effort_age, effort_city: @effort.effort_city, effort_country: @effort.effort_country, effort_id: @effort.effort_id, effort_state: @effort.effort_state, event_id: @effort.event_id, official_finish: @effort.official_finish, participant_id: @effort.participant_id, start_time: @effort.start_time, wave: @effort.wave }
    assert_redirected_to effort_path(assigns(:effort))
  end

  test "should destroy effort" do
    assert_difference('Effort.count', -1) do
      delete :destroy, id: @effort
    end

    assert_redirected_to efforts_path
  end
end
