class CarmenController < ApplicationController
  def subregion_options
    respond_to do |format|
      format.turbo_stream
    end
  end
end
