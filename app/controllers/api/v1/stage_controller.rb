class Api::V1::StageController < ApplicationController

  def get_locations
    ArgsValidator.validate(params: params, required: [:north, :south, :east, :west])
    if params[:west].to_f >= params[:east].to_f
      @locations = Location.where( 'latitude <= ? AND latitude >= ?', params[:north], params[:south] )
          .where( 'longitude <= ? OR longitude >= ?', params[:east], params[:west] )
    else
      @locations = Location.where( 'latitude <= ? AND latitude >= ?', params[:north], params[:south] )
          .where( 'longitude <= ? AND longitude >= ?', params[:east], params[:west] )
    end
    render partial: 'locations.json.ruby'
  end

end