require "rails_helper"

RSpec.describe "Madmin index pages" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }

  before { login_as admin_user, scope: :user }
  after { Warden.test_reset! }

  index_paths = %w[
    /madmin/active_storage/attachments
    /madmin/active_storage/blobs
    /madmin/active_storage/variant_records
    /madmin/aid_stations
    /madmin/analytics/email_events
    /madmin/analytics/file_downloads
    /madmin/analytics/sms_inbound_messages
    /madmin/connections
    /madmin/course_group_courses
    /madmin/course_group_finishers
    /madmin/course_groups
    /madmin/courses
    /madmin/crew_passages
    /madmin/efforts
    /madmin/event_groups
    /madmin/event_series
    /madmin/event_series_events
    /madmin/events
    /madmin/export_jobs
    /madmin/friendly_id/slugs
    /madmin/gating_location_events
    /madmin/gating_locations
    /madmin/historical_facts
    /madmin/import_jobs
    /madmin/lotteries
    /madmin/lotteries/entrant_service_details
    /madmin/lottery_divisions
    /madmin/lottery_draws
    /madmin/lottery_entrants
    /madmin/lottery_simulation_runs
    /madmin/lottery_simulations
    /madmin/lottery_tickets
    /madmin/monetary_donations
    /madmin/notifications
    /madmin/organizations
    /madmin/paper_trail/versions
    /madmin/partners
    /madmin/people
    /madmin/raw_times
    /madmin/results_categories
    /madmin/results_template_categories
    /madmin/results_templates
    /madmin/shortener/shortened_urls
    /madmin/split_times
    /madmin/splits
    /madmin/stewardships
    /madmin/subscriptions
    /madmin/users
  ]

  index_paths.each do |path|
    it "renders #{path}" do
      get path

      expect(response).to have_http_status(:ok)
    end
  end

  it "renders association columns with display names rather than 'Model #N' labels" do
    get "/madmin/efforts"

    effort = efforts(:hardrock_2014_finished_first)
    expect(response.body).to include(effort.event.name)
    expect(response.body).not_to match(/Event #\d+/)
  end
end
