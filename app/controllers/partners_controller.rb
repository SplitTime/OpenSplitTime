class PartnersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner, except: [:index, :new, :create]
  after_action :verify_authorized

  def show
  end

  def new
    @partner = Partner.new(event_group_id: params[:event_group_id])
    authorize @partner
  end

  def edit
    authorize @partner
  end

  def create
    @partner = Partner.new(permitted_params)
    authorize @partner

    if @partner.save
      redirect_to partner_event_group_path
    else
      render 'new'
    end
  end

  def update
    authorize @partner

    if @partner.update(permitted_params)
      redirect_to partner_event_group_path
    else
      render 'edit'
    end
  end

  def destroy
    authorize @partner
    @partner.destroy
    flash[:success] = 'Partner deleted.'
    redirect_to partner_event_group_path
  end

  private

  def partner_event_group_path
    event_group_path(@partner.event_group, display_style: 'partners', force_settings: true)
  end

  def set_partner
    @partner = Partner.find(params[:id])
  end
end
