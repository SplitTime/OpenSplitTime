class PartnerAdsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_partner_ad, except: [:index, :new, :create]
  after_action :verify_authorized

  def show
  end

  def new
    @partner_ad = PartnerAd.new
    authorize @partner_ad
  end

  def edit
    authorize @partner_ad
  end

  def create
    @partner_ad = PartnerAd.new(permitted_params)
    authorize @partner_ad

    if @partner_ad.save
      redirect_to @partner_ad
    else
      render 'new'
    end
  end

  def update
    authorize @partner_ad

    if @partner_ad.update(permitted_params)
      redirect_to @partner_ad
    else
      render 'edit'
    end
  end

  def destroy
    authorize @partner_ad
    @partner_ad.destroy
    flash[:success] = 'PartnerAd deleted.'
    redirect_to event_stage_path(@partner_ad.event), view: 'partners'
  end

  private

  def set_partner_ad
    @partner_ad = PartnerAd.find(params[:id])
  end
end
