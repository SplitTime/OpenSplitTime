# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  DEFAULT_DISPLAY_STYLE = "entrants"
  DEFAULT_SORT_HASH = {division_name: :asc, last_name: :asc}

  attr_reader :lottery, :params, :action_name
  delegate :divisions, :name, :organization, :scheduled_start_date, :to_param, to: :lottery

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
    @action_name = view_context.action_name
    @request = view_context.request
  end

  def lottery_draws
    lottery.draws
           .with_sortable_entrant_attributes
           .order(created_at: :desc)
  end

  def lottery_entrants
    entrants = lottery.entrants
                      .with_division_name
                      .includes(:division)
                      .search(search_text)

    reordering_needed = sort_hash.present? || search_text.blank?
    entrants = entrants.reorder(order_param) if reordering_needed

    entrants
  end

  def lottery_entrants_paginated
    @lottery_entrants_paginated ||= lottery_entrants.paginate(page: page, per_page: per_page).to_a
  end

  def lottery_tickets
    tickets = lottery.tickets
                     .with_sortable_entrant_attributes
                     .includes(entrant: :division)
                     .search(search_text)

    reordering_needed = sort_hash.present? || search_text.blank?
    tickets = tickets.reorder(order_param) if reordering_needed

    tickets
  end

  def lottery_tickets_paginated
    @lottery_tickets_paginated ||= lottery_tickets.paginate(page: page, per_page: per_page).to_a
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if records_from_context_count == per_page
  end

  def records_from_context
    case display_style
    when "entrants"
      lottery_entrants_paginated
    when "tickets"
      lottery_tickets_paginated
    when "draws"
      lottery_draws
    end
  end

  def records_from_context_count
    @records_from_context_count ||= records_from_context.size
  end

  def display_style
    params[:display_style].presence || DEFAULT_DISPLAY_STYLE
  end

  def page
    params[:page]&.to_i || 1
  end

  def per_page
    params[:per_page]&.to_i || 25
  end

  private

  attr_reader :view_context, :current_user, :request

  def order_param
    sort_hash.presence || DEFAULT_SORT_HASH
  end
end
