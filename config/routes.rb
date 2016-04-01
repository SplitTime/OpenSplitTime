Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'about', to: 'visitors#about'
  get 'donations', to: 'visitors#donations'
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
  devise_for :users, :controllers => {registrations: 'registrations'}
  resources :users do
    member { get :participants }
    member { put :associate_participant }
    member { post :add_interest }
    collection { get :my_interests }
  end
  resources :locations
  resources :courses
  resources :events do
    member { post :import_splits }
    member { post :import_efforts }
    member { get :splits }
    member { put :associate_split }
    member { put :associate_splits }
    member { get :reconcile }
  end
  resources :splits
  resources :races
  resources :event_splits, only: [:show, :destroy] do
    collection { delete :bulk_destroy }
  end
  resources :participants do
    collection { get :subregion_options }
    member { get :avatar_claim }
    member { delete :avatar_disclaim }
    collection { post :create_from_efforts }
    collection { get :search }
  end
  resources :efforts, only: [:show, :edit] do
    member { put :associate_participant }
    collection { put :associate_participants}
  end
  resources :interests
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  namespace :api do
    resources :courses, :efforts, :events, :locations, :participants, :split_times, :splits, :races
  end
end
