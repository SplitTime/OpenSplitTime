require "rails_helper"

RSpec.describe Organization, type: :model do
  it_behaves_like "auditable"
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }
  subject(:organization) { described_class.new(name: name, owner_id: owner_id) }
  let(:name) { nil }
  let(:owner_id) { owner.id }
  let(:owner) { users(:third_user) }

  describe "#initialize" do
    context "when created with a unique name" do
      let(:name) { "Test Organization" }
      it "is valid" do
        expect(organization).to be_valid
      end
    end

    context "without a name" do
      let(:name) { nil }
      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:name]).to include("can't be blank")
      end
    end

    context "with a duplicate name" do
      let(:name) { "Hardrock" }
      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:name]).to include("has already been taken")
      end
    end

    context "without an owner" do
      let(:owner_id) { nil }
      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:owner_id]).to include("does not exist")
      end
    end

    context "with an owner id that does not exist" do
      let(:owner_id) { -1 }
      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:owner_id]).to include("does not exist")
      end
    end
  end

  describe "#owner" do
    context "when the owner exists" do
      it "returns the user object" do
        expect(subject.owner).to eq(owner)
      end
    end

    context "when the owner does not exist" do
      let(:owner_id) { nil }
      it "returns nil" do
        expect(subject.owner).to be_nil
      end
    end
  end

  describe "#owner_full_name" do
    context "when the owner exists" do
      it "returns the full name of the owner" do
        expect(subject.owner_full_name).to eq(owner.full_name)
      end
    end

    context "when the owner does not exist" do
      let(:owner_id) { nil }
      it "returns nil" do
        expect(subject.owner_full_name).to be_nil
      end
    end
  end

  describe "#owner_email" do
    context "when the owner exists" do
      it "returns the email of the owner" do
        expect(subject.owner_email).to eq(owner.email)
      end
    end

    context "when the owner does not exist" do
      let(:owner_id) { nil }
      it "returns nil" do
        expect(subject.owner_email).to be_nil
      end
    end
  end

  describe "#owner_email=" do
    before { subject.owner_email = provided_email }
    context "when the email exists" do
      let(:provided_email) { users(:third_user).email }
      it "sets owner_id to the related user id" do
        expect(subject.owner_id).to eq(users(:third_user).id)
      end
    end

    context "when the email does not exist" do
      let(:provided_email) { "random@email.com" }
      it "sets owner_id to not found" do
        expect(subject.owner_id).to eq(Organization::NOT_FOUND_OWNER_ID)
      end
    end

    context "when the email provided is nil" do
      let(:provided_email) { nil }
      it "sets owner_id to not found" do
        expect(subject.owner_id).to eq(Organization::NOT_FOUND_OWNER_ID)
      end
    end
  end
end
