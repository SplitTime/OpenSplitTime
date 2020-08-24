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

        serialize_and_render(@resource)
      end

      def create
        @resource = controller_class.new(permitted_params)
        authorize @resource

        if @resource.save
          serialize_and_render(@resource, status: :created)
        else
          render_errors(@resource)
        end
      end

      def update
        authorize @resource

        if @resource.update(permitted_params)
          serialize_and_render(@resource, status: :updated)
        else
          render_errors(@resource)
        end
      end

      def destroy
        authorize @resource

        if @resource.destroy
          serialize_and_render(@resource, status: :deleted)
        else
          render_errors(@resource)
        end
      end

      private

      def render_errors(resource)
        render json: {errors: [jsonapi_error_object(resource)]}, status: :unprocessable_entity
      end

      def serialize_and_render(resource, options = {})
        status = options[:status] || :ok
        serializer_class = options[:serializer] || serializer_for(resource.class)
        serializer = serializer_class.new(resource,
                                          {params: {current_user: current_user},
                                           include: params[:include],
                                           fields: prepared_params[:fields]})
        render json: serializer.to_json, status: status
      end

      def serializer_for(klass)
        namespace = "::Api::V1::"
        serializer_name = klass.name.to_s.demodulize.classify + "Serializer"
        serializer_class_name = namespace + serializer_name
        begin
          serializer_class_name.constantize
        rescue NameError
          raise NameError, "#{self.name} cannot resolve a serializer class for '#{name}'.  " \
                           "Attempted to find '#{serializer_class_name}'. " \
                           "Consider specifying the serializer directly through options[:serializer]."
        end
      end

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
