# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def new_event(event, user)
    @event = event
    @user = user
    mail(to: ENV['ADMIN_EMAIL'], subject: "New event: #{@event.name}")
  end
end
