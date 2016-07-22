class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@opensplittime.org"
  layout 'mailer'
end