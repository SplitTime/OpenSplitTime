# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: {errors: ['record not found']}, status: :not_found}
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
      format.json { render json: {errors: ['unprocessable entity']}, status: :unprocessable_entity}
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: {errors: ['internal server error']}, status: :internal_server_error}
    end
  end
end
