# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  DEFAULT_DISPLAY_STYLE = "entrants"
  DEFAULT_SORT_HASH = {division_name: :asc, last_name: :asc}

  attr_reader :lottery, :params
  delegate :name, :organization, :scheduled_start_date, :to_param, to: :lottery

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
  end

  def lottery_entrants
    entrants = lottery.entrants
                      .with_division_name
                      .search(search_text)

    reordering_needed = sort_hash.present? || search_text.blank?
    entrants = entrants.reorder(order_param) if reordering_needed

    entrants
  end

  def lottery_tickets
    tickets = lottery.tickets
                     .with_entrant_attributes
                     .search(search_text)

    reordering_needed = sort_hash.present? || search_text.blank?
    tickets = tickets.reorder(order_param) if reordering_needed

    tickets
  end

  def display_style
    params[:display_style].presence || DEFAULT_DISPLAY_STYLE
  end

  private

  def order_param
    sort_hash.presence || DEFAULT_SORT_HASH
  end

  attr_reader :view_context, :current_user
end
