# frozen_string_literal: true

module UrlAccessible
  extend ::ActiveSupport::Concern

  def api_v1_url
    path_helper_name = "api_v1_#{model_name.element}_path"
    Rails.application.routes.url_helpers.send(path_helper_name, self)
  end
end
