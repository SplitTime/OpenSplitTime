class EffortsController < ApplicationController
  before_action :set_effort, only: [:show, :edit, :update, :destroy]

  # GET /efforts
  # GET /efforts.json
  def index
    @efforts = Effort.all
  end

  # GET /efforts/1
  # GET /efforts/1.json
  def show
  end

  # GET /efforts/new
  def new
    @effort = Effort.new
  end

  # GET /efforts/1/edit
  def edit
  end

  # POST /efforts
  # POST /efforts.json
  def create
    @effort = Effort.new(effort_params)

    respond_to do |format|
      if @effort.save
        format.html { redirect_to @effort, notice: 'Effort was successfully created.' }
        format.json { render :show, status: :created, location: @effort }
      else
        format.html { render :new }
        format.json { render json: @effort.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /efforts/1
  # PATCH/PUT /efforts/1.json
  def update
    respond_to do |format|
      if @effort.update(effort_params)
        format.html { redirect_to @effort, notice: 'Effort was successfully updated.' }
        format.json { render :show, status: :ok, location: @effort }
      else
        format.html { render :edit }
        format.json { render json: @effort.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /efforts/1
  # DELETE /efforts/1.json
  def destroy
    @effort.destroy
    respond_to do |format|
      format.html { redirect_to efforts_url, notice: 'Effort was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_effort
      @effort = Effort.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def effort_params
      params.require(:effort).permit(:effort_id, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :effort_age, :start_time, :official_finish)
    end
end
