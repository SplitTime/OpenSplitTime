class Api::V1::AidStationsController < ApiController
  before_action :set_aid_station, except: :create

  def show
    authorize @aid_station
    render json: @aid_station, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    aid_station = AidStation.new(permitted_params)
    authorize aid_station

    if aid_station.save
      render json: aid_station, status: :created
    else
      render json: {errors: ['aid_station not created'], detail: aid_station.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update
    authorize @aid_station
    if @aid_station.update(permitted_params)
      render json: @aid_station
    else
      render json: {errors: ['aid_station not updated'], detail: "#{@aid_station.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @aid_station
    if @aid_station.destroy
      render json: @aid_station
    else
      render json: {errors: ['aid_station not destroyed'], detail: "#{@aid_station.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  private

  def set_aid_station
    @aid_station = AidStation.find(params[:id])
  end
end
