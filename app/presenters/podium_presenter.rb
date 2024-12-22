# frozen_string_literal: true

class PodiumPresenter < BasePresenter
  attr_reader :event

  delegate :name, :course, :course_name, :organization, :organization_name, :to_param, :multiple_laps?,
           :event_group, :ordered_events_within_group, :results_template, :scheduled_start_time_local, to: :event
  delegate :available_live, :multiple_events?, to: :event_group
  delegate :course_groups, to: :course

  def initialize(event, view_context, template:)
    @event = event
    @params = view_context.prepared_params
    @template = template
  end

  # @return [Array<Results::Category>]
  def categories
    template&.categories || []
  end

  # @return [Array<Symbol>]
  def sort_methods
    results_template.includes_nonbinary? ? [:category] : [:category, :best_performance]
  end

  # @return [Array<Results::Category>]
  def sorted_categories
    if performance_sort?
      performance_sorted_categories
    else
      categories
    end
  end

  # @return [Symbol]
  def sort_method
    params[:sort].keys.first&.to_sym || :category
  end

  # @return [String]
  def template_name
    template&.name
  end

  # @return [Boolean]
  def point_system?
    template&.point_system.present?
  end

  private

  attr_reader :template, :params

  # @return [Boolean]
  def performance_sort?
    sort_method == :best_performance
  end

  # @return [Array<Results::Category>]
  def performance_sorted_categories
    ordered_fixed_categories + ordered_floating_categories
  end

  # @return [Array<Results::Category>]
  def ordered_fixed_categories
    categories.select(&:fixed_position?)
        .group_by { |c| [c.low_age, c.high_age] }.values
        .map { |category_pair| category_pair.sort_by(&:best_performance).reverse }
        .flatten
  end

  # @return [Array<Results::Category>]
  def ordered_floating_categories
    categories.reject(&:fixed_position?)
        .partition(&:male?)
        .map { |gender_group| gender_group.sort_by(&:best_performance).reverse }
        .transpose
        .map { |category_pair| category_pair.sort_by(&:best_performance).reverse }
        .flatten
  end
end
