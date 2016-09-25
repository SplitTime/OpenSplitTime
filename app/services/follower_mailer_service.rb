class FollowerMailerService

  def self.send_live_effort_mail(participant_id, split_time_ids)
    return unless participant_id.present?
    live_effort_mail_data = LiveEffortMailData.new(participant_id, split_time_ids)
    live_effort_mail_data.followers.each do |follower|
      FollowerMailer.live_effort_email(follower, live_effort_mail_data.effort_data).deliver_later
    end
  end

end