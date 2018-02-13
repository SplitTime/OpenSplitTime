class AdminMailer < ApplicationMailer
  def new_event(event, user)
    @event = event
    @user = user
    p "ADMIN_EMAIL is #{ENV['ADMIN_EMAIL']}"
    mail(to: ENV['ADMIN_EMAIL'], subject: "New event: #{@event.name}")
  end
end
