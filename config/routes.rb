Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'photo_credits', to: 'visitors#photo_credits'
  get 'about', to: 'visitors#about'
  get 'privacy_policy', to: 'visitors#privacy_policy'
  get 'donations', to: 'visitors#donations'
  get 'bitcoin_donations', to: 'visitors#bitcoin_donations'
  get 'donation_cancel', to: 'visitors#donation_cancel'
  get 'donation_thank_you', to: 'visitors#donation_thank_you'
  get 'documentation', to: redirect('docs/contents')
  get 'getting_started', to: redirect('docs/getting_started')
  get 'management', to: redirect('docs/management')
  get 'ost_remote', to: redirect('docs/ost_remote')

  get '/404', to: "errors#not_found"
  get '/422', to: "errors#unprocessable_entity"
  get '/500', to: "errors#internal_server_error"

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]

  namespace :docs do
    root to: 'visitors#contents'
    get 'contents', to: 'visitors#contents'
    get 'getting_started', to: 'visitors#getting_started'
    get 'management', to: 'visitors#management'
    get 'ost_remote', to: 'visitors#ost_remote'
    get 'api', to: 'visitors#api'
  end

  devise_for :users, controllers: {passwords: 'users/passwords', registrations: 'users/registrations', sessions: 'users/sessions'}

  resources :users do
    member do
      get :people
      get :edit_preferences
      get :my_stuff
      put :update_preferences
    end
  end

  resources :aid_stations, only: [:show, :create, :update, :destroy]

  resources :courses do
    member { get :best_efforts }
    member { get :plan_effort }
  end

  resources :efforts do
    collection do
      get :subregion_options
      post :mini_table
    end
    member do
      get :analyze
      get :audit
      get :projections
      get :place
      get :show_photo
      get :edit_split_times
      patch :update_split_times
      patch :set_data_status
      patch :rebuild
      patch :unstart
      patch :stop
      delete :delete_split_times
    end
  end

  resources :duplicate_event_groups, only: [:new, :create]

  resources :event_groups, only: [:index, :show, :edit, :update, :destroy] do
    member do
      get :drop_list
      get :follow
      get :raw_times
      get :reconcile
      get :roster
      get :export_raw_times
      get :split_raw_times
      get :stats
      get :traffic
      post :create_people
      patch :set_data_status
      patch :auto_reconcile
      patch :associate_people
      patch :start_efforts
      patch :update_all_efforts
      delete :delete_all_times
      delete :delete_duplicate_raw_times
    end
  end

  resources :event_series, only: [:show, :new, :create, :edit, :update, :destroy]

  resources :events, except: :index do
    member do
      get :admin
      get :edit_start_time
      get :export_finishers
      get :export_to_ultrasignup
      get :podium
      get :spread
      get :summary
      put :set_stops
      patch :reassign
      patch :update_start_time
      delete :delete_all_efforts
    end
  end

  get '/events', to: redirect('event_groups')

  resources :organizations

  resources :people do
    collection { get :subregion_options }
    member { get :avatar_claim }
    member { delete :avatar_disclaim }
    member { get :merge }
    member { put :combine }
  end

  resources :partners
  resources :raw_times, only: [:update, :destroy]

  resources :results_templates, only: [] do
    member { get :categories }
  end

  resources :split_times, only: [:update]
  resources :splits
  resources :stewardships, only: [:create, :destroy]
  resources :subscriptions, only: [:create, :destroy]

  get '/sitemap.xml.gz', to: redirect("https://#{ENV['S3_BUCKET']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz"), as: :sitemap

  namespace :admin do
    get 'dashboard', to: 'dashboard#show'
    get 'dashboard/timeout', to: 'dashboard#timeout'
    post 'impersonate/start/:id', to: 'impersonate#start', as: 'impersonate_start'
    post 'impersonate/stop', to: 'impersonate#stop', as: 'impersonate_stop'
    resources :versions, only: [:index, :show]
  end

  namespace :live do
    resources :events, only: [] do
      member do
        get :progress_report
        get :aid_station_report
        get :aid_station_detail
      end
    end

    resources :event_groups, only: [] do
      member { get :live_entry }
    end
  end

  namespace :api do
    namespace :v1 do
      resources :aid_stations, only: [:show, :create, :update, :destroy]
      resources :courses, only: [:index, :show, :create, :update, :destroy]
      resources :efforts, only: [:show, :create, :update, :destroy] do
        member do
          get :with_times_row
        end
      end
      resources :event_groups, only: [:index, :show, :create, :update, :destroy] do
        member do
          get :enrich_raw_time_row
          get :trigger_raw_times_push
          get :not_expected
          post :import
          post :import_csv_raw_times
          post :submit_raw_time_rows
          patch :pull_raw_times
        end
      end
      resources :events, only: [:index, :show, :create, :update, :destroy] do
        member do
          get :spread
          post :import
          put :associate_splits
          delete :remove_splits
        end
      end
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
