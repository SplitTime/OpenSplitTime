# frozen_string_literal: true

class UserReportsController < ::ApplicationController
  before_action :authenticate_user!

  # GET /user_reports
  def index
    current_user.update(reports_viewed_at: ::Time.current)
    render locals: { user_reports: current_user.reports.includes(:blob).order(created_at: :desc) }
  end

  # DELETE /user_reports/:id
  def destroy
    report = current_user.reports.find(params[:id])

    if report.present?
      report.purge_later
    else
      flash[:danger] = "The report was not found."
    end

    redirect_to user_reports_path
  end
end
