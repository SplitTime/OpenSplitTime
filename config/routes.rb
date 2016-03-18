Rails.application.routes.draw do
  root to: 'visitors#index'
  get 'about', to: 'pages#about'
  devise_for :users, :controllers => { registrations: 'registrations' }
  resources :users
  resources :locations
  resources :courses do
    member { post :import }
  end
  resources :events do
    member { post :import }
  end
  resources :splits
  resources :races

  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  namespace :api do
    resources :courses, :efforts, :events, :locations, :participants, :split_times, :splits, :races
  end
end
