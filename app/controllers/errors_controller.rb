# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render status: 404 }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render status: 422 }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: 500 }
    end
  end
end
