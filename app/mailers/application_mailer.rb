class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ENV['BASE_URI']}"
  # layout 'mailer'
end
