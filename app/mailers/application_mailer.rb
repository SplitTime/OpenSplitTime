# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{::OstConfig.base_uri}"
  layout "mailer"
end
