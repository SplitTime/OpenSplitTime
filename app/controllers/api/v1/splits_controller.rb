class Api::V1::SplitsController < ApiController
  before_action :set_split, except: :create

  def show
    authorize @split
    render json: @split, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    split = Split.new(permitted_params)
    authorize split

    if split.save
      render json: split, status: :created
    else
      render json: {errors: ['split not created'], detail: "#{split.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def update
    authorize @split
    if @split.update(permitted_params)
      render json: @split
    else
      render json: {errors: ['split not updated'], detail: "#{@split.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @split
    if @split.destroy
      render json: @split
    else
      render json: {errors: ['split not destroyed'], detail: "#{@split.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  private

  def set_split
    @split = Split.friendly.find(params[:id])
  end
end
