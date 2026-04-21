# frozen_string_literal: true

class RemoveSmsPersonSubscriptions < ActiveRecord::Migration[8.1]
  def up
    Subscription
      .where(subscribable_type: "Person", protocol: Subscription.protocols[:sms])
      .delete_all
  end

  def down
    # Irreversible: deleted subscription records are not recoverable.
    # Person subscriptions never sent any SMS messages, so no data of
    # value is lost. Re-enabling person SMS subscriptions (which would
    # require rolling back the UI change in #1924) does not depend on
    # restoring the deleted rows.
  end
end
