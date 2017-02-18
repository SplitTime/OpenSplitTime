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
  get 'organization_info', to: 'visitors#organization_info'
  get 'split_info', to: 'visitors#split_info'
  get 'split_time_info', to: 'visitors#split_time_info'
  get 'split_time_info', to: 'visitors#split_time_info'

  get '/.well-known/acme-challenge/:id' => 'visitors#letsencrypt'

  devise_for :users, :controllers => {registrations: 'registrations'}
  resources :users do
    member { get :participants }
    member { post :add_interest }
    member { post :remove_interest }
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
    member { post :import_efforts_military_times }
    member { post :import_efforts_without_times }
    member { get :splits }
    member { put :associate_splits }
    member { put :set_data_status }
    member { put :set_dropped_attributes }
    member { put :start_all_efforts }
    member { delete :remove_splits }
    member { delete :delete_all_efforts }
    member { get :reconcile }
    member { post :create_participants }
    member { get :stage }
    member { get :spread }
    member { put :live_enable }
    member { put :live_disable }
    member { get :add_beacon }
    member { get :drop_list }
    member { get :export_to_ultrasignup }
    member { get :find_problem_effort }
  end
  resources :splits do
    member { get :assign_location }
    member { post :create_location }
  end
  resources :organizations do
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
    member { post :current_user_follow }
    member { post :current_user_unfollow }
  end
  resources :efforts do
    collection { put :associate_participants }
    member { put :edit_split_times }
    member { patch :update_split_times }
    member { put :start }
    member { delete :delete_split_times }
    member { put :confirm_split_times }
    member { put :set_data_status }
    member { get :analyze }
    member { get :place }
    collection { post :mini_table }
    member { get :add_beacon }
    member { get :add_report }
    member { put :add_photo }
    member { get :show_photo }
    collection { get :subregion_options }
  end
  resources :split_times
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
      member { get :aid_station_detail }
    end
  end

  namespace :api do
    namespace :v1 do
      resources :courses, only: [:show, :create, :update, :destroy]
      resources :efforts, only: [:show, :create, :update, :destroy]
      resources :events, only: [:show, :create, :update, :destroy], param: :staging_id do
        member { delete :remove_splits }
        member { put :associate_splits }
      end
      resources :locations, only: [:show, :create, :update, :destroy]
      resources :organizations, only: [:show, :create, :update, :destroy]
      resources :participants, only: [:show, :create, :update, :destroy]
      resources :split_times, only: [:show, :create, :update, :destroy]
      resources :splits, only: [:show, :create, :update, :destroy]
      get 'staging/:staging_id/get_countries', to: 'staging#get_countries', as: :staging_get_countries
      get 'staging/:staging_id/get_courses', to: 'staging#get_courses', as: :staging_get_courses
      get 'staging/:staging_id/get_event', to: 'staging#get_event', as: :staging_get_event
      get 'staging/:staging_id/get_locations', to: 'staging#get_locations', as: :staging_get_locations
      get 'staging/:staging_id/get_organizations', to: 'staging#get_organizations', as: :staging_get_organizations
      post 'staging/:staging_id/post_event_course_org', to: 'staging#post_event_course_org', as: :staging_post_event_course_org
    end
  end

  namespace :event_staging do
    get 'new', to: 'events#new'
    get '/:staging_id/app', to: 'events#app', as: 'app'
  end
end