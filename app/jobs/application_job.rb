# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base

  private

  def set_current_user(options)
    User.current ||= options.delete(:current_user)
  end
end
