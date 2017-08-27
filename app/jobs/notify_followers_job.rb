class NotifyFollowersJob < ApplicationJob
  def perform(args)
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
    FollowerNotifier.publish(topic_arn: live_effort_mail_data.topic_resource_key, effort_data: live_effort_mail_data.effort_data)
  end
end
