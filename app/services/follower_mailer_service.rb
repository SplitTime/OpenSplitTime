class FollowerMailerService
  def self.send_live_effort_mail(args)
    ArgsValidator.validate(params: args,
                           required: [:participant_id, :split_time_ids],
                           exclusive: [:participant_id, :split_time_ids, :multi_lap],
                           class: self)
    participant_id = args[:participant_id]
    split_time_ids = args[:split_time_ids]
    multi_lap = args[:multi_lap]
    return unless participant_id.present? && split_time_ids.compact.present?
    live_effort_mail_data =
        LiveEffortMailData.new(participant_id: participant_id, split_time_ids: split_time_ids, multi_lap: multi_lap)
    live_effort_mail_data.followers.each do |follower|
      FollowerMailer.live_effort_email(follower, live_effort_mail_data.effort_data).deliver_later
    end
  end
end