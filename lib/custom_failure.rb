# frozen_string_literal: true

# Ensure we respond with 401 instead of redirecting
# when any unauthenticated request is made to the API
class CustomFailure < ::Devise::FailureApp
  def respond
    if request.original_fullpath.start_with?("/api")
      http_auth
    else
      super
    end
  end
end
