# Not currently working. Sidekiq seems not to handle the nested jobs. Use FollowerMailerService instead.

class FollowerMailerJob < ActiveJob::Base

  queue_as :default # Perhaps this should be 'mailers'

  def perform(participant_id, split_time_ids)
    live_effort_mail_data = LiveEffortMailData.new(participant_id: participant_id, split_time_ids: split_time_ids)
    live_effort_mail_data.followers.each do |follower|
      FollowerMailer.live_effort_email(follower, live_effort_mail_data.effort_data).deliver_later
    end
  end

end