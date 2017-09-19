class PartnersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner, except: [:index, :new, :create]
  after_action :verify_authorized

  def show
  end

  def new
    @partner = Partner.new(event_id: params[:event_id])
    authorize @partner
  end

  def edit
    authorize @partner
  end

  def create
    @partner = Partner.new(permitted_params)
    authorize @partner

    if @partner.save
      redirect_to partner_event_path
    else
      render 'new'
    end
  end

  def update
    authorize @partner

    if @partner.update(permitted_params)
      redirect_to partner_event_path
    else
      render 'edit'
    end
  end

  def destroy
    authorize @partner
    @partner.destroy
    flash[:success] = 'Partner deleted.'
    redirect_to partner_event_path
  end

  private

  def partner_event_path
    stage_event_path(@partner.event, display_style: 'partners')
  end

  def set_partner
    @partner = Partner.find(params[:id])
  end
end
