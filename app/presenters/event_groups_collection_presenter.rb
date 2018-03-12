# frozen_string_literal: true

class EventGroupsCollectionPresenter < BasePresenter
  attr_reader :event_groups

  def initialize(event_groups, params, current_user)
    @event_groups = event_groups
    @params = params
    @current_user = current_user
  end

  def show_visibility_columns?
    current_user&.admin? || current_user&.stewardships.present?
  end

  private

  attr_reader :params, :current_user
end
