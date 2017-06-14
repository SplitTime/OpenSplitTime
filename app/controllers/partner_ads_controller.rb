class PartnerAdsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner_ad, except: [:index, :new, :create]
  after_action :verify_authorized

  def show
  end

  def new
    @partner_ad = PartnerAd.new(event_id: params[:event_id])
    authorize @partner_ad
  end

  def edit
    authorize @partner_ad
  end

  def create
    @partner_ad = PartnerAd.new(permitted_params)
    authorize @partner_ad

    if @partner_ad.save
      redirect_to partner_ad_event_path
    else
      render 'new'
    end
  end

  def update
    authorize @partner_ad

    if @partner_ad.update(permitted_params)
      redirect_to partner_ad_event_path
    else
      render 'edit'
    end
  end

  def destroy
    authorize @partner_ad
    @partner_ad.destroy
    flash[:success] = 'PartnerAd deleted.'
    redirect_to partner_ad_event_path
  end

  private

  def partner_ad_event_path
    stage_event_path(@partner_ad.event, view: 'partners')
  end

  def set_partner_ad
    @partner_ad = PartnerAd.find(params[:id])
  end
end
