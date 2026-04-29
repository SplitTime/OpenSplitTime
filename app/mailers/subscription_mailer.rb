class SubscriptionMailer < ApplicationMailer
  def welcome(subscription)
    @subscription = subscription
    @user = subscription.user
    @subscribable = subscription.subscribable
    mail(to: @user.email, subject: subject_for(@subscribable))
  end

  private

  def subject_for(subscribable)
    case subscribable
    when Effort
      "You're following #{subscribable.full_name} at #{subscribable.event_name}"
    when Person
      "You're following #{subscribable.full_name}"
    end
  end
end
