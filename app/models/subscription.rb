require "aws-sdk-sns"

class Subscription < ApplicationRecord
  has_paper_trail

  enum :protocol, { :email => 0, :sms => 1, :http => 2, :https => 3 }
  belongs_to :user
  belongs_to :subscribable, polymorphic: true

  before_destroy :delete_resource_key
  after_create_commit :enqueue_sms_welcome, if: :sms?
  after_save :enqueue_email_welcome, if: :email_just_confirmed?

  # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo -- existing tests assert error messages on the column-level :user_id / :subscribable_id keys, which the explicit presence validators emit and the belongs_to default does not.
  validates :user_id, :subscribable_type, :subscribable_id, :endpoint, :user, :subscribable, :protocol, presence: true
  # rubocop:enable Rails/RedundantPresenceValidationOnBelongsTo
  validates_with ResourceKeyValidator
  validates :endpoint,
            uniqueness: { scope: [:user_id, :subscribable_type, :subscribable_id, :protocol],
                          message: lambda { |object, data|
                            "#{data[:value]} is already subscribed to #{object.subscribable.slug} by #{object.protocol}"
                          } }

  scope :for_user, ->(user) { where(user: user) }
  scope :pending, -> { where("resource_key like 'pending%'") }

  def delete_resource_key
    if should_locate_resource?
      locate_response = SnsSubscriptionManager.locate(subscription: self)
      self.resource_key = locate_response.subscription_arn
    end
    return unless confirmed?

    delete_response = SnsSubscriptionManager.delete(subscription: self)
    if delete_response.successful?
      self.resource_key = nil
    else
      errors.add(:base, "Could not delete subscription: #{delete_response.error_message}")
      throw(:abort)
    end
  end

  def pending?
    resource_key.present? && resource_key.include?("pending")
  end

  def confirmed?
    resource_key.present? && resource_key.include?("arn:aws:sns")
  end

  def to_s
    "Subscription for #{user&.slug} following #{subscribable&.slug} by #{protocol}"
  end

  private

  def should_locate_resource?
    pending? && required_data_present?
  end

  def required_data_present?
    subscribable&.topic_resource_key.present? && endpoint.present?
  end

  def email_just_confirmed?
    email? && saved_change_to_resource_key? && confirmed?
  end

  def enqueue_sms_welcome
    SmsSubscriptionWelcomeJob.perform_later(self)
  end

  def enqueue_email_welcome
    SubscriptionMailer.welcome(self).deliver_later
  end
end
