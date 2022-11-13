# frozen_string_literal: true

class UserExportsController < ::ApplicationController
  before_action :authenticate_user!
  after_action :set_exports_viewed_at

  # GET /user_exports
  def index
    render locals: { user_exports: current_user.exports.includes(:blob).order(created_at: :desc) }
  end

  # DELETE /user_exports/:id
  def destroy
    export = current_user.exports.find(params[:id])

    if export.present?
      export.purge_later
    else
      flash[:danger] = "The export was not found."
    end

    redirect_to user_exports_path
  end

  private

  def set_exports_viewed_at
    current_user.update(exports_viewed_at: ::Time.current)
  end
end