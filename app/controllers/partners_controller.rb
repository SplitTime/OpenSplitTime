# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner, except: [:index, :new, :create]
  before_action :set_partnerable
  before_action :authorize_organization
  after_action :verify_authorized

  def new
    @partner = @partnerable.partners.new
  end

  def edit
  end

  def create
    @partner = @partnerable.partners.new(permitted_params)

    if @partner.save
      redirect_to partnerable_path
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    if @partner.update(permitted_params)
      redirect_to partnerable_path
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    @partner.destroy
    flash[:success] = "Partner deleted."
    redirect_to partnerable_path
  end

  private

  def authorize_organization
    authorize @partnerable.organization, policy_class: ::PartnerPolicy
  end

  def partnerable_path
    raise NotImplementedError, "partnerable_path must be implemented"
  end

  def set_partnerable
    raise NotImplementedError, "set_partnerable must be implemented"
  end

  def set_partner
    @partner = ::Partner.find(params[:id])
  end
end
