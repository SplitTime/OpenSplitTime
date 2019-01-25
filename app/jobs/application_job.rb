# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base

  private

  def set_current_user(options)
    # Do not inline 'user' otherwise the :current_user key
    # will not be removed from the options hash if User.current exists.
    # And this may break objects that test for exclusivity of arguments.
    user = options.delete(:current_user)
    User.current ||= user
  end
end
