# frozen_string_literal: true

class EventsCollectionPresenter < BasePresenter
  attr_reader :events

  def initialize(events, params, current_user)
    @events = events
    @params = params
    @current_user = current_user
  end

  def show_visibility_columns?
    current_user&.admin? || current_user&.stewardships.present?
  end

  private

  attr_reader :params, :current_user
end
