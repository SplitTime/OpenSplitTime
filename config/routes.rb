Rails.application.routes.draw do
  draw :madmin

  root to: "visitors#index"
  get "photo_credits", to: "visitors#photo_credits"
  get "about", to: "visitors#about"
  get "privacy_policy", to: "visitors#privacy_policy"
  get "terms", to: "visitors#terms"
  get "donations", to: "visitors#donations"
  get "bitcoin_donations", to: "visitors#bitcoin_donations"
  get "donation_cancel", to: "visitors#donation_cancel"
  get "donation_thank_you", to: "visitors#donation_thank_you"
  get "documentation", to: redirect("docs/contents")
  get "getting_started", to: redirect("docs/getting_started")
  get "management", to: redirect("docs/management")
  get "ost_remote", to: redirect("docs/ost_remote")
  get "carmen/subregion_options"
  get "strong_confirm", to: "strong_confirm#show"

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unprocessable_entity"
  get "/500", to: "errors#internal_server_error"

  require "sidekiq/web"
  require "sidekiq/cron/web"
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  authenticate :user, ->(u) { u.admin? } do
    mount Coverband::Reporters::Web.new, at: "/coverage", as: :coverage
  end

  namespace :docs do
    root to: "visitors#contents"
    get "contents", to: "visitors#contents"
    get "getting_started", to: "visitors#getting_started"
    get "management", to: "visitors#management"
    get "ost_remote", to: "visitors#ost_remote"
    get "api", to: "visitors#api"
  end

  scope :my_stuff, controller: :my_stuff, as: :my_stuff do
    get '/', action: :index
    get :events
    get :event_series
    get :interests
    get :live_updates
    get :organizations
    get :results
    get :service_requirements
  end

  namespace :webhooks do
    resources :sendgrid_events, only: [:create]
  end

  namespace :user_settings do
    get :preferences
    get :password
    get :credentials
    get :credentials_new_service
    put :update
  end

  devise_for :users, controllers: {
    confirmations: "users/confirmations",
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions",
  }

  devise_scope :user do
    get "/users/auth/failure" => "users/omniauth_callbacks#failure"
  end

  resources :users, only: [:index, :update, :destroy]

  resources :credentials, only: [:create, :update, :destroy]

  resources :efforts do
    resources :subscriptions, only: [:create, :destroy], module: "efforts"
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
      get :start_form
      get :live_entry_table
      post :create_split_time_from_raw_time
      patch :update_split_times
      patch :set_data_status
      patch :rebuild
      patch :unstart
      patch :start
      patch :stop
      patch :smart_stop
      delete :delete_photo
      delete :delete_split_times
    end
  end

  resources :duplicate_event_groups, only: [:new, :create]

  resources :event_groups, only: [:index, :show] do
    resources :connect_service, only: [:show], module: "event_groups"
    resources :connections, only: [:index, :new, :create, :destroy], module: "event_groups"

    resources :events, except: [:index, :show] do
      resources :splits, except: [:show]
      member do
        get :new_course_gpx
        get :setup_course
        patch :reassign
        patch :attach_course_gpx
        delete :remove_course_gpx
      end
      resources :connections, only: [:create, :destroy], module: "events"
    end

    member do
      get :assign_bibs
      get :drop_list
      get :efforts
      get :entrants
      get :export_raw_times
      get :finish_line
      get :follow
      get :manage_entrant_photos
      get :manage_start_times
      get :manage_start_times_edit_actual
      get :raw_times
      get :reconcile
      get :roster
      get :setup
      get :setup_summary
      get :split_raw_times
      get :start_efforts_form
      get :stats
      get :traffic
      get :webhooks
      post :create_people
      patch :set_data_status
      patch :assign_entrant_photos
      patch :auto_assign_bibs
      patch :auto_reconcile
      patch :associate_people
      patch :start_efforts
      patch :update_all_efforts
      patch :update_bibs
      patch :update_entrant_photos
      delete :delete_all_efforts
      delete :delete_all_times
      delete :delete_duplicate_raw_times
      delete :delete_entrant_photos
      delete :delete_photos_from_entrants
    end
  end

  resources :events, only: [:show] do
    resources :connector_services, only: [], module: "events/connectors", controller: "services", param: "service_identifier" do
      member do
        get :preview_sync
        post :sync
      end
    end

    resources :aid_stations, only: [:create, :destroy]

    resources :subscriptions, only: [:new, :create, :destroy], module: "events" do
      member { patch :refresh }
    end

    member do
      get :admin
      get :edit_start_time
      get :export
      get :finish_history
      get :podium
      get :spread
      get :summary
      put :set_stops
      patch :update_start_time
    end
  end

  get "/events", to: redirect("event_groups")

  resources :export_jobs, only: [:index, :show, :destroy]
  resources :import_jobs, only: [:index, :show, :new, :create, :destroy] do
    collection { get :csv_templates }
  end

  resources :organizations do
    resources :course_groups, except: [:index] do
      resources :best_efforts, only: [:index], controller: "course_group_best_efforts" do
        collection { post :export_async }
      end
      resources :finishers, only: [:index, :show], controller: "course_group_finishers" do
        collection { post :export_async }
      end
    end

    resources :courses do
      resources :best_efforts, only: [:index], controller: "course_best_efforts"

      member do
        get :cutoff_analysis
        get :plan_effort
      end
    end

    resources :event_groups, except: [:index, :show] do
      resources :partners, except: [:show], module: "event_groups"
    end

    resources :event_series, except: [:index]

    resources :historical_facts do
      collection { patch :auto_reconcile }
      collection { get :reconcile }
      collection { patch :match }
    end

    resources :lotteries do
      member { get :calculations }
      member { get :download_service_form }
      member { get :draw_tickets }
      member { get :export_entrants }
      member { get :setup }
      member { get :withdraw_entrants }
      member { post :sync_calculations }
      member { post :draw }
      member { post :generate_entrants }
      member { post :generate_tickets }
      member { patch :attach_service_form }
      member { delete :delete_draws }
      member { delete :delete_entrants }
      member { delete :remove_service_form }
      member { delete :delete_tickets }
      resources :lottery_divisions, except: [:index, :show]
      resources :lottery_entrants, except: [:index] do
        member { post :draw }
      end
      resources :entrant_service_details, only: [:show], module: :lotteries do
        member { get :download_completed_form }
        member { patch :attach_completed_form }
        member { delete :remove_completed_form }
      end
      resources :lottery_simulation_runs, only: [:index, :show, :new, :create, :destroy]
      resources :partners, except: [:show], module: "lotteries"
    end

    resources :stewardships, only: [:index, :create, :update, :destroy]
  end

  resources :people, only: [:index, :show, :edit, :update, :destroy] do
    resources :subscriptions, only: [:create, :destroy], module: "people"
    collection { get :subregion_options }
    member { patch :avatar_claim }
    member { get :merge }
    member { put :combine }
  end

  resources :raw_times, only: [:update, :destroy]
  resources :results_templates, only: [:show]
  resources :split_times, only: [:update, :destroy]
  resources :toasts, only: [:create]

  get "/sitemap.xml.gz", to: redirect("https://#{::OstConfig.aws_s3_bucket_public}.s3.amazonaws.com/sitemaps/sitemap.xml.gz"), as: :sitemap

  namespace :admin do
    get "dashboard", to: "dashboard#show"
    get "dashboard/timeout", to: "dashboard#timeout"
    post "impersonate/start/:id", to: "impersonate#start", as: "impersonate_start"
    post "impersonate/stop", to: "impersonate#stop", as: "impersonate_stop"
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
      member do
        get :live_entry
        get :trigger_raw_times_push
      end
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
          post :enrich_raw_time_row
          get :not_expected
          post :import
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
      resources :users, only: [] do
        collection { get :current }
      end
      post "auth", to: "authentication#create"
    end
  end

  get "/courses(/*path)" => redirect(::NamespaceRedirector.new("courses"))
  get "/s/:id" => "shortener/shortened_urls#show"

  # Handle unmatched routes with 404, but allow routes from
  # active storage, action mailbox, and turbo to pass through
  match "*unmatched", to: "application#route_not_found", via: :all,
        constraints: lambda { |request|
          request.path.exclude?("rails/active_storage") &&
            request.path.exclude?("rails/action_mailbox") &&
            request.path.exclude?("rails/conductor") &&
            request.path.exclude?("recede_historical_location") &&
            request.path.exclude?("resume_historical_location") &&
            request.path.exclude?("refresh_historical_location")
        }
end
