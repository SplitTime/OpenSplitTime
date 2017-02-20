class FollowerMailer < ApplicationMailer
  helper :mail

  def live_effort_email(follower, effort_data)
    @follower = follower
    @effort_data = effort_data
    puts "Sending email to #{@follower.full_name}."
    mail(to: @follower.email, subject: "Update for #{@effort_data[:full_name]} at #{@effort_data[:event_name]} from OpenSplitTime")
  end
end