# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    protected

    # The path used after resending confirmation instructions.
    def after_resending_confirmation_instructions_path_for(_resource_name)
      "/"
    end

    # The path used after confirmation.
    def after_confirmation_path_for(_resource_name, _resource)
      "/"
    end
  end
end
