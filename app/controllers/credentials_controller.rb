# frozen_string_literal: true

class CredentialsController < ApplicationController
  before_action :authenticate_user!

  # POST /credentials
  def create
    @credential = current_user.credentials.new(credential_params)

    if @credential.save
      redirect_to user_settings_credentials_path, notice: "Credential was successfully created."
    else
      redirect_to user_settings_credentials_path, notice: "Credential could not be created: #{@credential.errors.full_messages}"
    end
  end

  # PATCH/PUT /credentials/1
  def update
    @credential = current_user.credentials.find(params[:id])

    if @credential.update(credential_params)
      redirect_to user_settings_credentials_path, notice: "Credential was successfully updated."
    else
      redirect_to user_settings_credentials_path, notice: "Credential could not be updated: #{@credential.errors.full_messages}"
    end
  end

  # DELETE /credentials/1
  def destroy
    @credential = current_user.credentials.find(params[:id])
    @credential.destroy

    redirect_to user_settings_credentials_path, notice: "Credential was successfully destroyed."
  end

  private

  def credential_params
    params.require(:credential).permit(:service_identifier, :key, :value)
  end
end
