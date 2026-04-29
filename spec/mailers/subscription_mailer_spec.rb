require "rails_helper"

RSpec.describe SubscriptionMailer, type: :mailer do
  let(:user) { users(:admin_user) }

  describe "#welcome" do
    context "with an Effort subscription" do
      let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
      let(:subscription) do
        Subscription.create!(user: user, subscribable: effort, protocol: :email, endpoint: user.email)
      end
      let(:mail) { described_class.welcome(subscription) }

      it "sends to the subscribed user's email" do
        expect(mail.to).to eq([user.email])
      end

      it "puts the participant name and event name in the subject" do
        expect(mail.subject).to include(effort.full_name)
        expect(mail.subject).to include(effort.event_name)
      end

      it "includes the effort full name and event name in the body" do
        expect(mail.body.encoded).to include(effort.full_name)
        expect(mail.body.encoded).to include(effort.event_name)
      end

      it "renders an aid-station mention specific to effort subscriptions" do
        expect(mail.body.encoded).to match(/aid station/)
      end
    end

    context "with a Person subscription" do
      let(:person) { people(:tuan_jacobs) }
      let(:subscription) do
        Subscription.create!(user: user, subscribable: person, protocol: :email, endpoint: user.email)
      end
      let(:mail) { described_class.welcome(subscription) }

      it "puts the person name in the subject" do
        expect(mail.subject).to include(person.full_name)
      end

      it "includes the person full name in the body" do
        expect(mail.body.encoded).to include(person.full_name)
      end

      it "renders the registered-for-event language specific to person subscriptions" do
        expect(mail.body.encoded).to match(/registered for upcoming events/)
      end
    end
  end
end
