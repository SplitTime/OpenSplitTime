class ReconcileSmsCarrierOptOutsJob < ApplicationJob
  queue_as :default

  def perform
    opted_out_at_by_phone = AwsSmsClient.opted_out_at_by_phone
    aws_phones = opted_out_at_by_phone.keys
    corrected_user_ids = []

    User.where(phone: aws_phones, sms_carrier_opted_out_at: nil).find_each do |user|
      user.update_column(:sms_carrier_opted_out_at, opted_out_at_by_phone[user.phone])
      corrected_user_ids << user.id
    end

    User.where.not(sms_carrier_opted_out_at: nil).where.not(phone: aws_phones).find_each do |user|
      user.update_column(:sms_carrier_opted_out_at, nil)
      corrected_user_ids << user.id
    end

    return if corrected_user_ids.empty?

    raise SmsReconciliationDriftError,
          "Reconciliation made #{corrected_user_ids.size} correction(s); " \
          "webhook is dropping events. Affected user_ids: #{corrected_user_ids.inspect}"
  end
end

class SmsReconciliationDriftError < StandardError; end
