# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  attr_reader :lottery, :params
  delegate :name, :organization, :scheduled_start_date, :to_param, to: :lottery

  def initialize(lottery, view_context)
    @lottery = lottery
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
  end

  def lottery_entrants
    lottery.lottery_entrants.with_division_name
  end

  private

  attr_reader :view_context, :current_user
end
