# frozen_string_literal: true

class LotteryPresenter < BasePresenter
  attr_reader :lottery
  delegate :name, :organization, :scheduled_start_date, :to_param, to: :lottery

  def initialize(lottery, params, current_user)
    @lottery = lottery
    @params = params
    @current_user = current_user
  end

  private

  attr_reader :params, :current_user
end
