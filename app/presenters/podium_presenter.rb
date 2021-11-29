# frozen_string_literal: true

class PodiumPresenter < BasePresenter

  attr_reader :event
  delegate :name, :course, :course_name, :organization, :organization_name, :to_param, :multiple_laps?,
           :event_group, :ordered_events_within_group, :scheduled_start_time_local, to: :event
  delegate :available_live, :multiple_events?, to: :event_group

  def initialize(event, template, params, current_user)
    @event = event
    @template = template
    @params = params
    @current_user = current_user
  end

  def categories
    template&.results_categories || []
  end

  def sorted_categories
    if fastest_seconds_sort?
      fastest_seconds_sorted_categories
    else
      categories
    end
  end

  def sort_method
    params[:sort].keys.first&.to_sym || :category
  end

  def template_name
    template&.name
  end

  def point_system?
    template&.point_system.present?
  end

  private

  def fastest_seconds_sort?
    sort_method == :fastest_times
  end

  def fastest_seconds_sorted_categories
    ordered_fixed_categories + ordered_floating_categories
  end

  def ordered_fixed_categories
    categories.select(&:fixed_position?)
      .group_by { |c| [c.low_age, c.high_age] }.values
      .map { |category_pair| category_pair.sort_by(&:fastest_seconds) }
      .flatten
  end

  def ordered_floating_categories
    categories.reject(&:fixed_position?)
      .partition(&:male?)
      .map { |gender_group| gender_group.sort_by(&:fastest_seconds) }
      .transpose
      .map { |category_pair| category_pair.sort_by(&:fastest_seconds) }
      .flatten
  end

  attr_reader :template, :params, :current_user
end
