# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  DEFAULT_SORT_HASH = { division_name: :asc, last_name: :asc }.freeze

  attr_reader :lottery, :params, :action_name

  delegate :concealed?, :divisions, :name, :organization, :scheduled_start_date, :status, :to_param, to: :lottery
  delegate :draws, :entrants, :tickets, to: :lottery, prefix: true

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
    @action_name = view_context.action_name
    @request = view_context.request
  end

  def ordered_divisions
    divisions.ordered_by_name
  end

  def lottery_draws_ordered
    lottery_draws
      .with_sortable_entrant_attributes
      .include_entrant_and_division
      .most_recent_first
  end

  def lottery_entrants_default_none
    unfiltered_entrants = lottery.entrants
                                 .with_division_name
                                 .includes(:division)
    entrant_id = params[:entrant_id]

    if entrant_id.present?
      unfiltered_entrants.where(id: entrant_id)
    else
      unfiltered_entrants.search_default_none(search_text)
    end
  end

  def lottery_entrants_paginated
    @lottery_entrants_paginated ||= lottery_entrants_filtered.paginate(page: page, per_page: per_page).to_a
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if records_from_context_count == per_page
  end

  def records_from_context
    case display_style
    when "entrants"
      lottery_entrants_paginated
    when "draws"
      lottery_draws
    end
  end

  def records_from_context_count
    @records_from_context_count ||= records_from_context.size
  end

  def viewable_results?
    lottery.live? || lottery.finished? || current_user&.authorized_for_lotteries?(lottery)
  end

  def display_style
    params[:display_style].presence || default_display_style
  end

  def default_display_style
    case status
    when "preview" then "entrants"
    when "live" then "draws"
    when "finished" then "results"
    else "entrants"
    end
  end

  def tickets_not_generated?
    @tickets_not_generated ||= lottery_tickets.empty?
  end

  def page
    params[:page]&.to_i || 1
  end

  def per_page
    params[:per_page]&.to_i || 25
  end

  private

  attr_reader :view_context, :current_user, :request

  def lottery_entrants_filtered
    lottery_entrants
      .includes(division: {lottery: :organization})
      .search(search_text)
  end
end
