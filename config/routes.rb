Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'photo_credits', to: 'visitors#photo_credits'
  get 'about', to: 'visitors#about'
  get 'donations', to: 'visitors#donations'
  get 'bitcoin_donations', to: 'visitors#bitcoin_donations'
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
  get 'person_info', to: 'visitors#person_info'
  get 'organization_info', to: 'visitors#organization_info'
  get 'split_info', to: 'visitors#split_info'
  get 'split_time_info', to: 'visitors#split_time_info'
  get 'split_time_info', to: 'visitors#split_time_info'

  devise_for :users, controllers: {passwords: 'users/passwords', registrations: 'users/registrations', sessions: 'users/sessions'}

  resources :users do
    member { get :people }
    member { get :edit_preferences }
    member { put :update_preferences }
  end

  resources :aid_stations, only: [:show, :create, :update, :destroy] do
    member { get :times }
  end

  resources :courses do
    member { get :best_efforts }
    member { get :plan_effort }
    member { get :segment_picker }
  end

  resources :efforts do
    collection do
      get :subregion_options
      post :mini_table
    end
    member do
      get :add_beacon
      get :add_report
      get :analyze
      get :place
      get :show_photo
      patch :update_split_times
      put :edit_split_times
      put :set_data_status
      put :start
      put :stop
      delete :delete_split_times
    end
  end

  resources :event_groups, only: [:show, :create, :edit, :update, :destroy]

  resources :events do
    collection { get :series }
    member do
      get :drop_list
      get :edit_start_time
      get :export_to_ultrasignup
      get :podium
      get :reconcile
      get :spread
      get :stage
      post :create_people
      put :associate_people
      put :set_data_status
      put :set_stops
      put :start_ready_efforts
      patch :update_start_time
      patch :update_all_efforts
      delete :delete_all_efforts
    end
  end

  resources :organizations

  resources :people do
    collection { get :subregion_options }
    member { get :avatar_claim }
    member { delete :avatar_disclaim }
    member { get :merge }
    member { put :combine }
  end

  resources :partners
  resources :split_times
  resources :splits
  resources :stewardships, only: [:create, :destroy]
  resources :subscriptions, only: [:create, :destroy]

  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  get '/races/:id' => 'organizations#show'

  get '/sitemap.xml.gz', to: redirect("https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz"), as: :sitemap

  namespace :admin do
    root 'dashboard#dashboard'
  end

  namespace :live do
    resources :events, only: [] do
      member { get :live_entry }
      member { get :progress_report }
      member { get :aid_station_report }
      member { get :effort_table }
      member { get :aid_station_detail }
    end

    resources :event_groups, only: [] do
      member { get :live_entry }
    end
  end

  namespace :api do
    namespace :v1 do
      resources :aid_stations, only: [:show, :create, :update, :destroy]
      resources :courses, only: [:index, :show, :create, :update, :destroy]
      resources :efforts, only: [:show, :create, :update, :destroy]
      resources :event_groups, only: [:index, :show, :create, :update, :destroy]
      resources :events, only: [:index, :show, :create, :update, :destroy] do
        member do
          delete :remove_splits
          put :associate_splits
          post :import
          get :spread
          get :event_data
          get :live_effort_data
          post :set_times_data
          post :post_file_effort_data
          patch :pull_live_time_rows
          get :trigger_live_times_push
        end
      end
      resources :live_times, only: [:index, :show, :create, :update, :destroy]
      resources :organizations, only: [:index, :show, :create, :update, :destroy]
      resources :people, only: [:index, :show, :create, :update, :destroy]
      resources :split_times, only: [:show, :create, :update, :destroy]
      resources :splits, only: [:show, :create, :update, :destroy]
      resources :users, only: [:show, :create, :update, :destroy] do
        collection { get :current }
      end
      post 'auth', to: 'authentication#create'
      get 'staging/get_countries', to: 'staging#get_countries', as: :staging_get_countries
      get 'staging/get_time_zones', to: 'staging#get_time_zones', as: :staging_get_time_zones
      get 'staging/:id/get_locations', to: 'staging#get_locations', as: :staging_get_locations
      post 'staging/:id/post_event_course_org', to: 'staging#post_event_course_org', as: :staging_post_event_course_org
      patch 'staging/:id/update_event_visibility', to: 'staging#update_event_visibility', as: :staging_update_event_visibility
    end
  end

  namespace :event_staging do
    get '/:id/app', to: 'events#app', as: 'app'
  end
end
