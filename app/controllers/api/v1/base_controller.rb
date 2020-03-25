module Api
  module V1
    class BaseController < ::ApiController
      before_action :set_default_format

      def index
        authorize controller_class
        authorized_scope = policy_class::Scope.new(current_user, controller_class)
        working_scope = prepared_params[:editable] ? authorized_scope.editable : authorized_scope.viewable
        @resources = working_scope.where(prepared_params[:filter]).order(prepared_params[:sort]).standard_includes
        paginate json: @resources, include: prepared_params[:include], fields: prepared_params[:fields]
      end

      def show
        authorize @resource
        render json: @resource, include: prepared_params[:include], fields: prepared_params[:fields]
      end

      def create
        @resource = controller_class.new(permitted_params)
        authorize @resource

        if @resource.save
          render json: @resource, status: :created
        else
          render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
        end
      end

      def update
        authorize @resource
        if @resource.update(permitted_params)
          render json: @resource
        else
          render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @resource
        if @resource.destroy
          render json: @resource
        else
          render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
        end
      end

      private

      def set_resource
        @resource = controller_class.respond_to?(:friendly) ?
                      controller_class.friendly.find(params[:id]) :
                      controller_class.find(params[:id])
      end

      def set_default_format
        request.format = :json
      end
    end
  end
end
