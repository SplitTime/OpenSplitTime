class FollowerMailer < ApplicationMailer

  helper :application

  def live_effort_email(follower, split_times)
    @follower = follower
    @split_times = split_times
    @effort = split_times.first.effort
    mail(to: @follower.email, subject: "Update for #{@effort.full_name} at #{@effort.event_name}")
  end

  def interest_new_event

  end

end