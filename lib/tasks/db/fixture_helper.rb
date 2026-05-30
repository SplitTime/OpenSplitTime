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
    :lottery_simulation_runs,
    :lottery_tickets,
    :monetary_donations,
    :notifications,
    :organizations,
    :partners,
    :people,
    :projection_assessment_runs,
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
    :aid_stations,
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
    :monetary_donations,
    :organizations,
    :partners,
    :people,
    :projection_assessment_runs,
    :results_categories,
    :results_templates,
    :results_template_categories,
    :splits,
    :stewardships,
    :users,
  ].freeze

  # ORDER BY clause used when dumping fixtures. Required for any non-slug portable table
  # so labels are stable across regenerations and across schema changes (otherwise a new
  # column could become an unexpected sort key, scrambling every label and FK reference).
  # Pick columns that uniquely identify a row by its real-world identity.
  ORDER_BY_MAP = {
    aid_stations: "event_id, split_id",
    credentials: "service_identifier, key, user_id",
    event_series_events: "event_series_id, event_id",
    historical_facts: "last_name, first_name, year, kind, personal_info_hash",
    monetary_donations: "received_on, organization_id, amount, source",
    partners: "partnerable_type, partnerable_id, name",
    projection_assessment_runs:
      "event_id, completed_lap, completed_split_id, completed_bitkey, " \
      "projected_lap, projected_split_id, projected_bitkey",
    results_template_categories: "results_template_id, position, results_category_id",
    stewardships: "user_id, organization_id",
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
