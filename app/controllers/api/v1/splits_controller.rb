class Api::V1::SplitsController < ApiController
  before_action :set_split, except: :create

  def show
    authorize @split
    render json: @split, include: params[:include], fields: params[:fields]
  end

  def create
    split = Split.new(permitted_params)
    authorize split

    if split.save
      render json: split, status: :created
    else
      render json: {message: 'split not created', error: "#{split.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @split
    if @split.update(permitted_params)
      render json: @split
    else
      render json: {message: 'split not updated', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @split
    if @split.destroy
      render json: @split
    else
      render json: {message: 'split not destroyed', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_split
    @split = Split.friendly.find(params[:id])
  end
end
