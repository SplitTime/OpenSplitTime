class LotteryDivisionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization
  before_action :set_lottery
  before_action :set_lottery_division, except: [:new, :create]
  after_action :verify_authorized

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions/new
  def new
    @lottery_division = @lottery.divisions.new
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions/:id/edit
  def edit
  end

  # POST /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions
  def create
    @lottery_division = @lottery.divisions.new(permitted_params)

    if @lottery_division.save
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "new", status: :unprocessable_entity
    end
  end

  # PUT   /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions/:id
  # PATCH /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions/:id
  def update
    if @lottery_division.update(permitted_params)
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:lottery_id/lottery_divisions/:id
  def destroy
    respond_to do |format|
      format.turbo_stream do
        if @lottery_division.tickets.exists?
          flash.now[:warning] = "A lottery division cannot be deleted unless all tickets and draws have been deleted first."
        elsif @lottery_division.destroy
          flash.now[:success] = "The division was deleted."
        else
          flash.now[:danger] = @lottery_division.errors.full_messages.join("\n")
        end

        render "destroy", status: :unprocessable_entity
      end
    end
  end

  private

  def authorize_organization
    authorize @organization, policy_class: ::LotteryDivisionPolicy
  end

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:lottery_id])
  end

  def set_lottery_division
    @lottery_division = policy_scope(@lottery.divisions).find(params[:id])
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end
end
