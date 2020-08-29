module Api
  module V1
    class BaseController < ::ApiController
      API_NAMESPACE = "::Api::V1::"

      before_action :set_default_format

      def index
        authorize controller_class

        authorized_scope = policy_class::Scope.new(current_user, controller_class)
        working_scope = prepared_params[:editable] ? authorized_scope.editable : authorized_scope.viewable
        @resources = working_scope.where(prepared_params[:filter]).order(prepared_params[:sort]).standard_includes
        @resources = paginate @resources

        serialize_and_render(@resources, is_collection: true)
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
          serialize_and_render(@resource)
        else
          render_errors(@resource)
        end
      end

      def destroy
        authorize @resource

        if @resource.destroy
          serialize_and_render(@resource)
        else
          render_errors(@resource)
        end
      end

      private

      def render_errors(resource)
        render json: {errors: [jsonapi_error_object(resource)]}, status: :unprocessable_entity
      end

      def serialize_and_render(resource, options = {})
        status = options.delete(:status) || :ok

        first_record = resource.is_a?(::Enumerable) ? resource.first : resource
        serializer_class = options.delete(:serializer) ||
          serializer_for_record(first_record) ||
          ::Api::V1::BaseSerializer

        options[:include] = *options[:include] if options[:include].present?
        options[:include] ||= prepared_params[:include]
        options[:fields] ||= prepared_params[:fields]
        serializer_params = {params: {current_user: current_user}}

        serializer = serializer_class.new(resource, serializer_params.merge(options))

        render json: serializer.serializable_hash.to_json, status: status
      end

      def serializer_for_record(record)
        return nil if record.nil?

        serializer_class_name = "#{API_NAMESPACE}#{record.model_name}Serializer"
        serializer_class_name.constantize
      rescue NameError
        raise NameError, "#{self.name} cannot resolve a serializer class for '#{record.model_name}'.  " \
                           "Attempted to find '#{serializer_class_name}'. " \
                           "Consider specifying the serializer directly through options[:serializer]."
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
