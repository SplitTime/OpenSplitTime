class Api::V1::SplitsController < ApiController
  before_action :set_resource, except: [:index, :create]

  def destroy
    authorize @resource
    if @resource.split_times.present?
      render json: {errors: [child_records_error_object(@resource, :split_times)]}, status: :unprocessable_entity
    else
      if @resource.destroy
        render json: @resource
      else
        render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
      end
    end
  end
end
