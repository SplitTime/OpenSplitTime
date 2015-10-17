class SplitTimesController < ApplicationController
  before_action :set_split_time, only: [:show, :edit, :update, :destroy]

  # GET /split_times
  # GET /split_times.json
  def index
    @split_times = SplitTime.all
  end

  # GET /split_times/1
  # GET /split_times/1.json
  def show
  end

  # GET /split_times/new
  def new
    @split_time = SplitTime.new
  end

  # GET /split_times/1/edit
  def edit
  end

  # POST /split_times
  # POST /split_times.json
  def create
    @split_time = SplitTime.new(split_time_params)

    respond_to do |format|
      if @split_time.save
        format.html { redirect_to @split_time, notice: 'Split time was successfully created.' }
        format.json { render :show, status: :created, location: @split_time }
      else
        format.html { render :new }
        format.json { render json: @split_time.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /split_times/1
  # PATCH/PUT /split_times/1.json
  def update
    respond_to do |format|
      if @split_time.update(split_time_params)
        format.html { redirect_to @split_time, notice: 'Split time was successfully updated.' }
        format.json { render :show, status: :ok, location: @split_time }
      else
        format.html { render :edit }
        format.json { render json: @split_time.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /split_times/1
  # DELETE /split_times/1.json
  def destroy
    @split_time.destroy
    respond_to do |format|
      format.html { redirect_to split_times_url, notice: 'Split time was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_split_time
      @split_time = SplitTime.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def split_time_params
      params.require(:split_time).permit(:splittime_id, :effort_id, :split_id, :time_from_start, :data_status)
    end
end
