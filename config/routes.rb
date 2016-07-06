Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'hardrock', to: 'visitors#hardrock'
  get 'photo_credits', to: 'visitors#photo_credits'
  get 'about', to: 'visitors#about'
  get 'donations', to: 'visitors#donations'
  get 'donation_cancel', to: 'visitors#donation_cancel'
  get 'donation_thank_you', to: 'visitors#donation_thank_you'
  get 'getting_started', to: 'visitors#getting_started'
  get 'getting_started_2', to: 'visitors#getting_started_2'
  get 'getting_started_3', to: 'visitors#getting_started_3'
  get 'getting_started_4', to: 'visitors#getting_started_4'
  get 'getting_started_5', to: 'visitors#getting_started_5'
  get 'course_info', to: 'visitors#course_info'
  get 'effort_info', to: 'visitors#effort_info'
  get 'event_info', to: 'visitors#event_info'
  get 'location_info', to: 'visitors#location_info'
  get 'participant_info', to: 'visitors#participant_info'
  get 'race_info', to: 'visitors#race_info'
  get 'split_info', to: 'visitors#split_info'
  get 'split_time_info', to: 'visitors#split_time_info'
  get 'split_time_info', to: 'visitors#split_time_info'
  devise_for :users, :controllers => {registrations: 'registrations'}
  resources :users do
    member { get :participants }
    member { put :associate_participant }
    member { post :add_interest }
    collection { get :my_interests }
    member { get :edit_preferences }
    member { put :update_preferences }
  end
  resources :locations
  resources :courses do
    member { get :best_efforts }
    member { get :plan_effort }
    member { get :segment_picker }
  end
  resources :events do
    member { post :import_splits }
    member { post :import_efforts }
    member { post :import_efforts_without_times }
    member { get :splits }
    member { put :associate_split }
    member { put :associate_splits }
    member { put :set_data_status }
    member { delete :remove_split }
    member { delete :remove_all_splits }
    member { delete :delete_all_efforts }
    member { get :reconcile }
    member { post :create_participants }
    member { get :stage }
    member { get :spread }
    member { put :live_enable }
    member { put :live_disable }
  end
  resources :splits do
    member { get :assign_location }
    member { post :create_location }
  end
  resources :races do
    member { get :stewards }
    member { put :remove_steward }
  end
  resources :participants do
    collection { get :subregion_options }
    member { get :avatar_claim }
    member { delete :avatar_disclaim }
    member { get :merge }
    member { put :combine }
    member { delete :remove_effort }
  end
  resources :efforts do
    member { put :associate_participant }
    collection { put :associate_participants }
    member { put :edit_split_times }
    member { delete :delete_split }
    member { put :confirm_split }
    member { put :set_data_status }
    member { get :analyze }
    member { get :place }
    collection { post :mini_table }
  end
  resources :split_times
  resources :interests
  resources :aid_stations, except: [:index, :new, :create]
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  namespace :admin do
    root 'dashboard#dashboard'
    put 'set_effort_ages', to: 'dashboard#set_effort_ages'
  end

  namespace :live do
    resources :events, only: [] do
      member { get :live_entry }
      member { get :progress_report }
      member { get :aid_station_report }
      member { get :get_event_data }
      member { get :get_live_effort_data }
      member { get :get_effort_table }
      member { post :post_file_effort_data }
      member { post :set_times_data }
      member { put :aid_station_degrade }
      member { put :aid_station_advance }
      member { get :aid_station_detail }
    end
  end

end
