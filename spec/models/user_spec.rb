require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }

  it "creates a valid user with name and email and password" do
    user_attr = FactoryBot.attributes_for(:user)
    user = described_class.create!(user_attr)

    expect(user).to be_valid
  end

  it "is invalid without a last name" do
    user = build_stubbed(:user, last_name: nil)
    expect(user).not_to be_valid
  end

  it "is invalid without an email" do
    user = build_stubbed(:user, email: nil)
    expect(user).not_to be_valid
  end

  it "is invalid with a first_name longer than 64 characters" do
    user = build_stubbed(:user, first_name: "a" * 65)
    expect(user).not_to be_valid
    expect(user.errors[:first_name]).to be_present
  end

  it "is invalid with a last_name longer than 64 characters" do
    user = build_stubbed(:user, last_name: "a" * 65)
    expect(user).not_to be_valid
    expect(user.errors[:last_name]).to be_present
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "1234567890",
        info: {
          first_name: first_name,
          last_name: last_name,
          email: "oauth-user@example.com",
        },
      )
    end
    let(:first_name) { "Jane" }
    let(:last_name) { "Doe" }

    context "with a normal-length first_name" do
      it "creates a valid user" do
        user = described_class.from_omniauth(auth)
        expect(user).to be_persisted
        expect(user.first_name).to eq("Jane")
      end
    end

    context "with a first_name longer than 64 characters" do
      let(:first_name) { "A" * 100 }

      it "truncates first_name and creates the user" do
        user = described_class.from_omniauth(auth)
        expect(user).to be_persisted
        expect(user.first_name.length).to eq(64)
      end
    end

    context "with a last_name longer than 64 characters" do
      let(:last_name) { "B" * 100 }

      it "truncates last_name and creates the user" do
        user = described_class.from_omniauth(auth)
        expect(user).to be_persisted
        expect(user.last_name.length).to eq(64)
      end
    end

    context "with a nil first_name" do
      let(:first_name) { nil }

      it "does not raise" do
        expect { described_class.from_omniauth(auth) }.not_to raise_error
      end
    end
  end

  describe "#normalize_phone" do
    subject(:user) { build(:user, phone: phone) }

    let(:normalized_phone) { "+12025551212" }

    context "when phone is a standard US or Canada number with +1 prefix" do
      let(:phone) { "+12025551212" }

      it "does not change phone and user is valid" do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context "when phone is a standard US or Canada number with 1 prefix" do
      let(:phone) { "12025551212" }

      it "normalizes phone number and user is valid" do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context "when phone is a standard US or Canada number without + or 1 prefix" do
      let(:phone) { "2025551212" }

      it "normalizes phone number and user is valid" do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context "when phone is a standard US or Canada number with +1 prefix and parentheses, spaces, and dashes" do
      let(:phone) { "+1 (202) 555-1212" }

      it "normalizes phone number and user is valid" do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context "when phone is a standard US or Canada number with parentheses, spaces, and dashes" do
      let(:phone) { "(202) 555-1212" }

      it "normalizes phone number and user is valid" do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context "when phone is a nonstandard number" do
      let(:phone) { "555-1212" }

      it "attempts to normalize phone number and user is not valid" do
        user.validate
        expect(user.phone).to eq("5551212")
        expect(user).not_to be_valid
      end
    end

    context "when phone is nonsensical" do
      let(:phone) { "hello234" }

      it "attempts to normalize phone number and user is not valid" do
        user.validate
        expect(user.phone).to eq("234")
        expect(user).not_to be_valid
      end
    end

    context "when phone contains no numeric data" do
      let(:phone) { "hello" }

      it "eliminates the data and user is valid" do
        user.validate
        expect(user.phone).to be_nil
        expect(user).to be_valid
      end
    end

    context "when phone has a leading non-+1 country code" do
      let(:phone) { "52+15517064638" }

      it "is rejected by the format validator" do
        user.validate
        expect(user.phone).to eq("52+15517064638")
        expect(user).not_to be_valid
        expect(user.errors[:phone]).to include("must be a valid US or Canada phone number")
      end
    end
  end

  describe "#steward_of?" do
    subject { build_stubbed(:user) }

    let(:organization) { build_stubbed(:organization, stewards: stewards) }
    let(:event_group) { build_stubbed(:event_group, organization: organization) }
    let(:event) { build_stubbed(:event, event_group: event_group) }
    let(:effort) { build_stubbed(:effort, event: event) }
    let(:split_time) { build_stubbed(:split_time, effort: effort) }

    context "when the user is a steward" do
      let(:stewards) { [subject] }

      [:organization, :event_group, :event, :effort, :split_time].each do |resource|
        context "when the provided resource is a/an #{resource}" do
          it "returns true" do
            expect(subject.steward_of?(send(resource))).to eq(true)
          end
        end
      end
    end

    context "when the user is not a steward" do
      let(:stewards) { [] }

      [:organization, :event_group, :event, :effort, :split_time].each do |resource|
        context "when the provided resource is a/an #{resource}" do
          it "returns false" do
            expect(subject.steward_of?(send(resource))).to eq(false)
          end
        end
      end
    end

    context "when the provided resource does not implement :stewards" do
      let(:user) { build_stubbed(:user) }

      it "returns false" do
        expect(subject.steward_of?(user)).to eq(false)
      end
    end
  end

  describe "#sms_opted_in?" do
    context "when phone and phone_confirmed_at are both present" do
      subject { build(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it { is_expected.to be_sms_opted_in }
    end

    context "when phone is present but phone_confirmed_at is nil" do
      subject { build(:user, phone: "+12025551212", phone_confirmed_at: nil) }

      it { is_expected.not_to be_sms_opted_in }
    end

    context "when phone_confirmed_at is present but phone is nil" do
      subject { build(:user, phone: nil, phone_confirmed_at: Time.current) }

      it { is_expected.not_to be_sms_opted_in }
    end

    context "when phone and phone_confirmed_at are both present but the user is carrier-opted-out" do
      subject { build(:user, phone: "+12025551212", phone_confirmed_at: Time.current, sms_carrier_opted_out_at: Time.current) }

      it { is_expected.not_to be_sms_opted_in }
    end
  end

  describe "#sms_carrier_opted_out?" do
    context "when sms_carrier_opted_out_at is set" do
      subject { build(:user, sms_carrier_opted_out_at: Time.current) }

      it { is_expected.to be_sms_carrier_opted_out }
    end

    context "when sms_carrier_opted_out_at is nil" do
      subject { build(:user, sms_carrier_opted_out_at: nil) }

      it { is_expected.not_to be_sms_carrier_opted_out }
    end
  end

  describe "sms consent callbacks" do
    context "when sms_consent is set to '1' with a phone number" do
      subject { build(:user, phone: "+12025551212", phone_confirmed_at: nil) }

      it "sets phone_confirmed_at on save" do
        subject.sms_consent = "1"
        subject.save!
        expect(subject.phone_confirmed_at).to be_present
      end
    end

    context "when sms_consent is set to '0'" do
      subject { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "clears phone_confirmed_at on save" do
        subject.sms_consent = "0"
        subject.save!
        expect(subject.phone_confirmed_at).to be_nil
      end
    end

    context "when phone is changed" do
      subject { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "clears phone_confirmed_at" do
        subject.update!(phone: "+13035551212")
        expect(subject.phone_confirmed_at).to be_nil
      end
    end

    context "when phone is cleared" do
      subject { create(:user, phone: "+12025551212", phone_confirmed_at: Time.current) }

      it "clears phone_confirmed_at" do
        subject.update!(phone: nil)
        expect(subject.phone_confirmed_at).to be_nil
      end
    end

    context "when phone is changed and the user is carrier-opted-out" do
      subject do
        create(:user,
               phone: "+12025551212",
               phone_confirmed_at: Time.current,
               sms_carrier_opted_out_at: Time.current)
      end

      it "clears both phone_confirmed_at and sms_carrier_opted_out_at" do
        subject.update!(phone: "+13035551212")
        expect(subject.phone_confirmed_at).to be_nil
        expect(subject.sms_carrier_opted_out_at).to be_nil
      end
    end
  end

  describe "#credentials_for?" do
    let(:user) { users(:third_user) }
    let(:result) { user.credentials_for?(service_identifier) }
    let(:service_identifier) { "runsignup" }

    context "when credentials exist for the requested service" do
      it { expect(result).to eq(true) }
    end

    context "when the identifier is passed as a symbol" do
      let(:service_identifier) { :runsignup }

      it { expect(result).to eq(true) }
    end

    context "when the user has no credentials" do
      before { user.credentials.delete_all }

      it { expect(result).to eq(false) }
    end

    context "when the user has credentials but not for the requested service" do
      let(:service_identifier) { "another_service" }

      it { expect(result).to eq(false) }
    end
  end

  describe "#all_credentials_for?" do
    let(:user) { users(:third_user) }
    let(:result) { user.all_credentials_for?(service_identifier) }
    let(:service_identifier) { "runsignup" }

    context "when all credentials exist for the requested service" do
      it { expect(result).to eq(true) }
    end

    context "when one credential is missing" do
      before { user.credentials.for_service(service_identifier).first.destroy! }

      it { expect(result).to eq(false) }
    end

    context "when the user has no credentials" do
      before { user.credentials.delete_all }

      it { expect(result).to eq(false) }
    end

    context "when the user has credentials but not for the requested service" do
      let(:service_identifier) { "another_service" }

      it { expect(result).to eq(false) }
    end
  end
end
