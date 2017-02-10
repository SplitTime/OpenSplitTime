class Api::V1::SplitTimesController < ApiController
  before_action :set_split_time, except: :create

  def show
    if @split_time
      authorize @split_time
      render json: @split_time, serializer: OstExchangeSerializer
    else
      skip_authorization
      render json: {error: 'not_found'}
    end
  end

  def create
    split_time = SplitTime.new(split_time_params)
    authorize split_time

    if split_time.save
      render json: split_time
    else
      render json: {error: "#{split_time.errors.full_messages}"}
    end
  end

  def update
    authorize @split_time
    if @split_time.update(split_time_params)
      render json: @split_time
    else
      render json: {error: "#{@split_time.errors.full_messages}"}
    end
  end

  def destroy
    authorize @split_time
    if @split_time.destroy
      render json: @split_time
    else
      render json: {error: "#{@split_time.errors.full_messages}"}
    end
  end

  private

  def set_split_time
    @split_time = SplitTime.find_by(id: params[:id])
  end

  def split_time_params
    params.require(:split_time).permit(:id, :name, :latitude, :longitude, :elevation, :description)
  end
end