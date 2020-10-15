class CarmenController < ApplicationController
  def subregion_options
    render partial: "subregion_select", locals: {model: :person, parent_region: params[:parent_region]}
  end
end
