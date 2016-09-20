class FollowerMailerPreview < ActionMailer::Preview
  def live_effort_email
    FollowerMailer.live_effort_email(User.first, SplitTime.last(2))
  end
end