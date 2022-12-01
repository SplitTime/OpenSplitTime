# frozen_string_literal: true

module Lotteries
  class PartnersController < ::PartnersController
    private

    def partnerable_path
      setup_organization_lottery_path(@partner.organization, @partner.partnerable)
    end

    def set_partnerable
      @partnerable = ::Lottery.find(params[:lottery_id])
    end
  end
end
