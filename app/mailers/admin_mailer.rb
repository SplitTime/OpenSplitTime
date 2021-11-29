# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def job_report(job, report_text)
    @report_text = report_text
    mail(to: ENV['ADMIN_EMAIL'], subject: "Job report: #{job}")
  end

  def new_event_group(event_group)
    @event_group = event_group
    @user = User.find_by(id: event_group.created_by) || User.new(first_name: 'Unknown', last_name: 'User')
    mail(to: ENV['ADMIN_EMAIL'], subject: "New event group: #{@event_group.name}")
  end
end
