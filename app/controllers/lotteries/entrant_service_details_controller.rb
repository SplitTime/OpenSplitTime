class Lotteries::EntrantServiceDetailsController < ApplicationController
  # Rails 7.0 is unable to generate a local URL for ActiveStorage using Disk service
  # unless ActiveStorage::Current.url_options is set
  before_action :set_current_url_options, only: [:download_completed_form]
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_lottery
  before_action :set_service_detail
  before_action :authorize_service_detail
  after_action :verify_authorized

  # GET /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id
  def show
    @presenter = Lotteries::EntrantServiceDetailPresenter.new(@service_detail)
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id/edit
  def edit
    params[:status] ||= @service_detail.status
  end

  # PUT /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id
  # PATCH /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id
  def update
    respond_to do |format|
      format.turbo_stream do
        if @service_detail.update(permitted_params)
          presenter = Lotteries::EntrantServiceDetailPresenter.new(@service_detail)
          render :update, locals: { presenter: presenter }
        else
          render :update_failed, locals: { service_detail: @service_detail }, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id/attach_completed_form
  def attach_completed_form
    completed_form = params.dig(:lotteries_entrant_service_detail, :completed_form)

    if completed_form.present?
      unless @service_detail.completed_form.attach(completed_form)
        flash[:danger] = "An error occurred while attaching service form: #{@service_detail.errors.full_messages}"
      end

      redirect_to organization_lottery_entrant_service_detail_path(@organization, @lottery, @service_detail)
    else
      redirect_to organization_lottery_entrant_service_detail_path(@organization, @lottery, @service_detail),
                  notice: "No completed service form was specified"
    end
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id/download_completed_form
  def download_completed_form
    if @service_detail.completed_form.attached?
      redirect_to @service_detail.completed_form.url(disposition: :attachment), allow_other_host: true
      record_file_download(@service_detail.completed_form)
    else
      redirect_to organization_lottery_entrant_service_detail_path(@organization, @lottery, @service_detail),
                  notice: "No completed service form is attached"
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:lottery_id/lotteries_entrant_service_details/:id/remove_completed_form
  def remove_completed_form
    @service_detail.completed_form.purge_later
    @service_detail.update(form_accepted_at: nil, form_rejected_at: nil, form_accepted_comments: nil, form_rejected_comments: nil, completed_date: nil)

    redirect_to organization_lottery_entrant_service_detail_path(@organization, @lottery, @service_detail), notice: "Service form was deleted."
  end

  private

  def authorize_service_detail
    authorize @service_detail
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:lottery_id])
  end

  def set_service_detail
    @lottery_entrant = @lottery.entrants.find(params[:id])
    @service_detail = @lottery_entrant.service_detail || @lottery_entrant.create_service_detail
    @service_detail.save! if @service_detail.new_record?
  end
end
