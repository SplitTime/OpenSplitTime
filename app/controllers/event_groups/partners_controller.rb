# frozen_string_literal: true

module EventGroups
  class PartnersController < ::PartnersController
    private

    def partnerable_path
      setup_event_group_path(@partner.partnerable, display_style: :partners)
    end

    def set_partnerable
      @partnerable = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
