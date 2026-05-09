class StrongConfirmController < ApplicationController
  def show
    render "show", locals: {
      path_on_confirm: params[:on_confirm],
      message: params[:message],
      required_pattern: params[:required_pattern],
      method: params[:method],
      button_text: params[:button_text],
    }
  end
end
