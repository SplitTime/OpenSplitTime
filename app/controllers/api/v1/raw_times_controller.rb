module Api
  module V1
    class RawTimesController < ::Api::V1::BaseController
      before_action :set_event_group
      before_action :authorize_event_group
      before_action :set_resource, only: [:show]

      def index
        @raw_times = @event_group.raw_times.where(prepared_params[:filter]).order(prepared_params[:sort])
        @raw_times = paginate @raw_times

        serialize_and_render(@raw_times, is_collection: true)
      end

      def show
        @raw_time = @event_group.raw_times.find(params[:id])

        serialize_and_render(@raw_time)
      end

      private

      def set_event_group
        @event_group = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.friendly.find(params[:event_group_id])
      end

      def authorize_event_group
        authorize @event_group
      end
    end
  end
end
