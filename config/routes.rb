Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'about', to: 'pages#about'
  devise_for :users, :controllers => {registrations: 'registrations'}
  resources :users do
    member { get :participants }
    member { put :associate_participant }
  end
  resources :locations
  resources :courses
  resources :events do
    member { post :import_splits }
    member { post :import_efforts }
    member { get :splits }
    member { put :associate_split }
    member { put :bulk_associate_splits }
    member { get :reconcile }
  end
  resources :splits
  resources :races
  resources :event_splits, only: [:show, :destroy] do
    delete 'bulk_destroy', on: :collection
  end
  resources :participants do
    collection { get :subregion_options}
    member { get :avatar_claim }
    member { delete :avatar_disclaim }
  end
  resources :efforts, only: [:show, :edit] do
    member { put :associate_participant }
  end
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  namespace :api do
    resources :courses, :efforts, :events, :locations, :participants, :split_times, :splits, :races
  end
end
