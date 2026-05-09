class BackfillSmsCarrierOptOutTimestamps < ActiveRecord::Migration[8.1]
  def up
    aws_index = fetch_aws_index
    return if aws_index.nil?

    User.where.not(sms_carrier_opted_out_at: nil).find_each do |user|
      aws_at = aws_index[user.phone]
      next if aws_at.nil?
      next if (user.sms_carrier_opted_out_at - aws_at).abs < 1.second

      user.update_column(:sms_carrier_opted_out_at, aws_at)
    end
  end

  def down
    # Irreversible: the original 2026-04-29 backfill timestamps were themselves
    # synthetic — produced by the first reconciliation run before the job knew
    # to consult AWS's OptedOutTimestamp. The AWS-reported timestamps that
    # this migration installs are the truth, so there is no meaningful prior
    # state to restore.
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Returns nil when AWS is unreachable (e.g., staging environments without
  # SMS infrastructure or IAM perms wired up). The migration then no-ops
  # rather than blocking the deploy.
  def fetch_aws_index
    AwsSmsClient.opted_out_at_by_phone
  rescue Aws::Errors::ServiceError, Aws::Errors::MissingCredentialsError => e
    say "Skipping backfill: AWS opt-out list unreachable (#{e.class}: #{e.message}). " \
        "Expected in environments without SMS infrastructure."
    nil
  end
end
