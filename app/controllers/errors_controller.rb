# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { record_not_found_json }
      format.js { record_not_found_json }
      format.text { record_not_found_json }
      format.csv { record_not_found_json }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
      format.json { unprocessable_entity_json }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { internal_server_error_json }
    end
  end
end
