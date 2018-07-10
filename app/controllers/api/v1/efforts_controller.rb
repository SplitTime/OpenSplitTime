class Api::V1::EffortsController < ApiController
  before_action :set_resource, except: [:index, :create]

  def show
    @resource.split_times.load.to_a if prepared_params[:include]&.include?('split_times')
    super
  end

  def with_times_row
    authorize @resource

    effort = Effort.where(id: @resource).includes(event: :splits, split_times: :split).first
    presenter = EffortWithTimesRowPresenter.new(effort: effort)
    render json: presenter, include: :effort_times_row, serializer: EffortWithTimesRowSerializer
  end
end
