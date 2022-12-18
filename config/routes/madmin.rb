# Below are the routes for madmin
namespace :madmin do
  namespace :active_storage do
    resources :variant_records
  end
  namespace :active_storage do
    resources :blobs
  end
  namespace :active_storage do
    resources :attachments
  end
  namespace :shortener do
    resources :shortened_urls
  end
  resources :best_effort_segments
  resources :aid_stations
  resources :subscriptions
  namespace :paper_trail do
    resources :versions
  end
  resources :people
  resources :partners
  resources :notifications
  resources :organizations
  resources :lottery_tickets
  resources :lottery_simulations
  resources :lottery_simulation_runs
  resources :lottery_entrants
  resources :lottery_division_ticket_stats
  resources :lottery_draws
  resources :lottery_divisions
  resources :lotteries
  resources :import_jobs
  resources :event_series_events
  resources :export_jobs
  resources :event_series
  resources :event_groups
  resources :effort_segments
  resources :users
  resources :events
  resources :versions
  namespace :friendly_id do
    resources :slugs
  end
  resources :stewardships
  resources :efforts
  resources :splits
  resources :split_times
  resources :course_group_courses
  resources :course_group_finishers
  resources :results_template_categories
  resources :results_templates
  resources :course_groups
  resources :results_categories
  resources :raw_times
  resources :courses
  root to: "dashboard#show"
end
