# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  DEFAULT_SORT_HASH = {number_of_tickets: :asc}

  attr_reader :lottery, :params
  delegate :name, :organization, :scheduled_start_date, :to_param, to: :lottery

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
  end

  def lottery_entrants
    lottery.lottery_entrants
           .with_division_name
           .search(search_text)
           .order(order_param)
  end

  private

  def order_param
    sort_hash.presence || DEFAULT_SORT_HASH
  end

  attr_reader :view_context, :current_user
end
