module FixtureHelper
  FIXTURE_TABLES = [
    :aid_stations,
    :connections,
    :course_group_courses,
    :course_groups,
    :courses,
    :credentials,
    :efforts,
    :event_groups,
    :event_series,
    :event_series_events,
    :events,
    :historical_facts,
    :lotteries,
    :lottery_divisions,
    :lottery_draws,
    :lottery_entrants,
    :lottery_tickets,
    :notifications,
    :organizations,
    :partners,
    :people,
    :raw_times,
    :results_categories,
    :results_template_categories,
    :results_templates,
    :split_times,
    :splits,
    :stewardships,
    :subscriptions,
    :users,
  ].freeze

  # Portable fixture tables are assigned an :id by Rails and are referenced by title
  # rather than id in other fixture tables.
  PORTABLE_FIXTURE_TABLES = [
    :results_categories,
    :results_templates,
    :results_template_categories,
  ].freeze

  PRIMARY_KEY_MAP = {
    effort_segments: "begin_split_id, begin_bitkey, end_split_id, end_bitkey, effort_id, lap",
  }.freeze


  ATTRIBUTES_TO_IGNORE = [
    :created_at,
    :confirmation_sent_at,
    :confirmation_token,
    :exports_viewed_at,
    :remember_created_at,
    :reset_password_token,
    :reset_password_sent_at,
    :updated_at,
  ].freeze

  ATTRIBUTES_TO_PRESERVE_BY_TABLE = {
    lottery_draws: [:created_at],
  }.freeze
end
