# frozen_string_literal: true

class LotteryEntrantsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_organization
  before_action :authorize_organization, except: [:show, :manage_service]
  before_action :set_lottery
  before_action :set_lottery_entrant, except: [:new, :create]
  before_action :authorize_lottery_entrant, only: [:manage_service]
  after_action :verify_authorized, except: [:show]

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  def show
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/new
  def new
    division = @lottery.divisions.first
    @lottery_entrant = division.entrants.new
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id/edit
  def edit
  end

  # POST /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants
  def create
    @lottery_entrant = LotteryEntrant.new(permitted_params)

    if @lottery_entrant.save
      redirect_to setup_organization_lottery_path(@lottery_entrant.organization, @lottery_entrant.lottery, entrant_id: @lottery_entrant.id)
    else
      render "new", status: :unprocessable_entity
    end
  end

  # PUT   /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  # PATCH /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  def update
    if @lottery_entrant.update(permitted_params)
      respond_to do |format|
        format.html do
          redirect_to manage_service_organization_lottery_lottery_entrant_path(@organization, @lottery, @lottery_entrant), notice: "Entrant was updated."
        end

        format.turbo_stream { @lottery_presenter = LotteryPresenter.new(@lottery, view_context) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id
  def destroy
    respond_to do |format|
      format.turbo_stream do
        if @lottery_entrant.tickets.exists?
          flash.now[:warning] = "A lottery entrant cannot be deleted unless all of the entrant's tickets and draws have been deleted first."
          render "destroy", status: :unprocessable_entity
        elsif @lottery_entrant.destroy
          flash[:success] = "The entrant was deleted."
          redirect_to setup_organization_lottery_path(@organization, @lottery)
        else
          flash.now[:danger] = @lottery_entrant.errors.full_messages.join("\n")
          render "destroy", status: :unprocessable_entity
        end
      end
    end
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id/draw
  def draw
    lottery_draw = @lottery_entrant.draw_ticket!

    if lottery_draw.present?
      head :created
    else
      head :no_content
    end
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_entrants/:id/manage_service
  def manage_service
    @presenter = LotteryEntrantPresenter.new(@lottery_entrant)
  end

  private

  def authorize_lottery_entrant
    authorize @lottery_entrant, policy_class: ::LotteryEntrantSpecialPolicy
  end

  def authorize_organization
    authorize @organization, policy_class: ::LotteryEntrantPolicy
  end

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
