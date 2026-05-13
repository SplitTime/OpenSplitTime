module Madmin
  class OrganizationUsagesController < Madmin::ApplicationController
    def index
      @presenter = OrganizationUsageIndexPresenter.new
    end

    def show
      @organization = Organization.friendly.find(params[:id])
      @presenter = OrganizationUsageShowPresenter.new(@organization)
    end
  end
end
