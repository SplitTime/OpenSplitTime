require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }

  it "creates a valid user with name and email and password" do
    user_attr = FactoryBot.attributes_for(:user)
    user = User.create!(user_attr)

    expect(user).to be_valid
  end

  it "is invalid without a last name" do
    user = build_stubbed(:user, last_name: nil)
    expect(user.valid?).to be_falsey
  end

  it "is invalid without an email" do
    user = build_stubbed(:user, email: nil)
    expect(user.valid?).to be_falsey
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

  describe "#has_credentials_for?" do
    let(:user) { users(:third_user) }
    let(:result) { user.has_credentials_for?(service_identifier) }
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
