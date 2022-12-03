# frozen_string_literal: true

module Lotteries
  class PartnersController < ::PartnersController
    def index
      @presenter = ::LotteryPresenter.new(@partnerable, view_context)
    end

    private

    def partnerable_path
      organization_lottery_partners_path(@partner.organization, @partner.partnerable)
    end

    def set_partnerable
      @partnerable = ::Lottery.friendly.find(params[:lottery_id])
    end
  end
end
