# frozen_string_literal: true

module Api
  module V1
    class SendgridEventsController < ::Api::V1::BaseController
      skip_before_action :authenticate_user!
      skip_after_action :verify_authorized

      def create
        skip_authorization

        head :ok
      rescue StandardError
        head :bad_request
      end
    end
  end
end
