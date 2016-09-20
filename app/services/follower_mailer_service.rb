class FollowerMailerService

  def self.send_mail(participant_id, split_time_ids)
    split_times = SplitTime.find(split_time_ids)
    participant = Participant.find(participant_id)
    participant.followers.each do |follower|
      FollowerMailer.live_effort_email(follower, split_times).deliver_later
    end
  end

end