# frozen_string_literal: true

module Api
  module V1
    class EffortsController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]

      def show
        @resource.split_times.load.to_a if prepared_params[:include]&.include?('split_times')
        super
      end

      def with_times_row
        authorize @resource

        effort = Effort.where(id: @resource).includes(event: :splits, split_times: :split).first
        effort.ordered_split_times.each_cons(2) do |begin_st, end_st|
          end_st.segment_time ||= end_st.absolute_time - begin_st.absolute_time
        end
        presenter = EffortWithTimesRowPresenter.new(effort)

        serialize_and_render(presenter, include: :effort_times_row, serializer: EffortWithTimesRowSerializer)
      end
    end
  end
end
