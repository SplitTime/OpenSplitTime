# frozen_string_literal: true

module FixtureHelper
  FIXTURE_TABLES = [
    :aid_stations,
    :course_group_courses,
    :course_groups,
    :courses,
    :credentials,
    :efforts,
    :event_groups,
    :event_series,
    :event_series_events,
    :events,
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
    :syncable_relations,
    :users,
  ].freeze

  ATTRIBUTES_TO_IGNORE = [
    :created_at,
    :confirmation_sent_at,
    :confirmation_token,
    :remember_created_at,
    :reset_password_token,
    :reset_password_sent_at,
    :updated_at,
  ].freeze

  ATTRIBUTES_TO_PRESERVE = {
    lottery_draws: [:created_at],
  }.freeze
end
