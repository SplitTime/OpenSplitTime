class ToastsController < ApplicationController
  before_action :authenticate_user!

  # POST /toasts
  def create
    respond_to do |format|
      format.turbo_stream do
        render "toasts/create", locals: { title: params[:title], body: params[:body], type: params[:type] }
      end
    end
  end
end
