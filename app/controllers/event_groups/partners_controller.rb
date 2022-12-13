# frozen_string_literal: true

module EventGroups
  class PartnersController < ::PartnersController
    def index
      @presenter = ::EventGroupSetupPresenter.new(@partnerable, view_context)
    end

    private

    def partnerable_path
      organization_event_group_partners_path(@partner.partnerable)
    end

    def set_partnerable
      @partnerable = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
