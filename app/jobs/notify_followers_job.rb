# frozen_string_literal: true

class NotifyFollowersJob < ApplicationJob
  def perform(args)
    ArgsValidator.validate(params: args,
                           required: [:person_id, :split_time_ids],
                           exclusive: [:person_id, :split_time_ids, :multi_lap],
                           class: self)
    person_id = args[:person_id]
    split_time_ids = args[:split_time_ids]
    multi_lap = args[:multi_lap]

    return unless person_id.present? && split_time_ids.compact.present?

    live_effort_mail_data = LiveEffortMailData.new(person_id: person_id, split_time_ids: split_time_ids, multi_lap: multi_lap)
    FollowerNotifier.publish(topic_arn: live_effort_mail_data.topic_resource_key, effort_data: live_effort_mail_data.effort_data)
  end
end
