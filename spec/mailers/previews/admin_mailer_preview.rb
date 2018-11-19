# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class AdminMailerPreview < ActionMailer::Preview
  def new_event
    event = Event.first
    user = User.first
    AdminMailer.new_event(event, user)
  end
end
