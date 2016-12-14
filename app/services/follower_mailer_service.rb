class FollowerMailerService

  def self.send_live_effort_mail(participant_id, split_time_ids)
    return unless participant_id.present? && split_time_ids.present?
    live_effort_mail_data = LiveEffortMailData.new(participant_id: participant_id, split_time_ids: split_time_ids)
    live_effort_mail_data.followers.each do |follower|
      FollowerMailer.live_effort_email(follower, live_effort_mail_data.effort_data).deliver_later
    end
  end

end