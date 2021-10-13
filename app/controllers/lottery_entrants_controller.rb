# frozen_string_literal: true

class LotteryEntrantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_lottery
  before_action :set_lottery_entrant, except: [:new, :create]
  after_action :verify_authorized

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/new
  def new
    division = @lottery.divisions.first
    @lottery_entrant = division.entrants.new
    authorize @lottery_entrant
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id/edit
  def edit
    authorize @lottery_entrant
  end

  # POST /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants
  def create
    division_id = params.dig(:lottery_entrant, :lottery_division_id)
    division = LotteryDivision.find(division_id)
    @lottery_entrant = division.entrants.new(permitted_params)
    authorize @lottery_entrant

    if @lottery_entrant.save
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "new"
    end
  end

  # PUT   /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  # PATCH /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  def update
    authorize @lottery_entrant

    if @lottery_entrant.update(permitted_params)
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "edit"
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  def destroy
    authorize @lottery_entrant

    if @lottery_entrant.tickets.present?
      flash[:warning] = "A lottery entrant cannot be deleted unless all of the entrant's tickets and draws have been deleted first."
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    elsif @lottery_entrant.destroy
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      flash[:danger] = @lottery_entrant.errors.full_messages.join("\n")
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    end
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id/draw
  def draw
    authorize @lottery_entrant

    lottery_draw = @lottery_entrant.draw_ticket!

    if lottery_draw.present?
      head :created
    else
      head :no_content
    end
  end

  private

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:lottery_id])
  end

  def set_lottery_entrant
    @lottery_entrant = policy_scope(@lottery.entrants).find(params[:id])
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end
end
