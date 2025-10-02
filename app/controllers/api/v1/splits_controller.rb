module Api
  module V1
    class SplitsController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]

      def destroy
        authorize @resource
        if @resource.split_times.present?
          render json: {errors: [child_records_error_object(@resource, :split_times)]}, status: :unprocessable_content
        else
          if @resource.destroy
            render json: @resource
          else
            render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_content
          end
        end
      end
    end
  end
end
