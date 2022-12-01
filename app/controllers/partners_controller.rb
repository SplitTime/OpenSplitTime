# frozen_string_literal: true

class PartnersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner, except: [:new, :create]
  before_action :set_partnerable
  after_action :verify_authorized

  def new
    @partner = @partnerable.partners.new
    authorize @partner
  end

  def edit
    authorize @partner
  end

  def create
    @partner = @partnerable.partners.new(permitted_params)
    authorize @partner

    if @partner.save
      redirect_to partnerable_path
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    authorize @partner

    if @partner.update(permitted_params)
      redirect_to partnerable_path
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @partner

    @partner.destroy
    flash[:success] = "Partner deleted."
    redirect_to partnerable_path
  end

  private

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
