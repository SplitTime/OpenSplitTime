# frozen_string_literal: true

class CredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_action
  after_action :verify_authorized

  # POST /credentials
  def create
    @credential = current_user.credentials.new(credential_params)
    @credential.save

    respond_to do |format|
      format.html do
        notice = @credential.errors.blank? ?
                   "Credential was successfully created." :
                   "Credential could not be created: #{credential.errors.full_messages}"

        redirect_to user_settings_credentials_path, notice: notice
      end

      format.turbo_stream { render :create, locals: { credential: @credential, user: current_user } }
    end
  end

  # PATCH/PUT /credentials/1
  def update
    @credential = current_user.credentials.find(params[:id])
    @credential.update(credential_params)

    respond_to do |format|
      format.html do
        notice = @credential.errors.blank? ?
                   "Credential was successfully updated." :
                   "Credential could not be updated: #{credential.errors.full_messages}"
        redirect_to user_settings_credentials_path, notice: notice
      end

      format.turbo_stream { render :update, locals: { credential: @credential, user: current_user } }
    end
  end

  # DELETE /credentials/1
  def destroy
    @credential = current_user.credentials.find(params[:id])
    @credential.destroy

    respond_to do |format|
      format.html { redirect_to user_settings_credentials_path, notice: "Credential was successfully destroyed." }
      format.turbo_stream do
        new_credential = current_user.credentials.new(service_identifier: @credential.service_identifier, key: @credential.key, updated_at: Time.current)
        render :destroy, locals: { credential: new_credential, user: current_user }
      end
    end
  end

  private

  def authorize_action
    authorize self, policy_class: ::CredentialPolicy
  end

  def credential_params
    params.require(:credential).permit(:service_identifier, :key, :value)
  end
end
