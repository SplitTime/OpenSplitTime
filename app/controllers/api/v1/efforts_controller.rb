class Api::V1::EffortsController < ApiController
  before_action :set_resource, except: :create

  def show
    @resource.split_times.load.to_a if prepared_params[:include]&.include?('split_times')
    super
  end
end
