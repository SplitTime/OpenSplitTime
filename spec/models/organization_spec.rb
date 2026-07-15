require "rails_helper"

RSpec.describe Organization, type: :model do
  subject(:organization) { described_class.new(name: name, owner_id: owner_id) }

  let(:owner) { users(:third_user) }
  let(:owner_id) { owner.id }
  let(:name) { nil }
  it_behaves_like "auditable"
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

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
      before { allow(User).to receive(:current).and_return(nil) }

      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:owner]).to include("must exist")
      end
    end

    context "with an owner id that does not exist" do
      let(:owner_id) { -1 }
      it "is invalid" do
        expect(subject).to be_invalid
        expect(subject.errors[:owner]).to include("must exist")
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

  describe ".visible_or_authorized_for" do
    subject(:found) { described_class.visible_or_authorized_for(user).friendly.find(historical_slug) }

    let(:user) { users(:third_user) }
    let(:existing_organization) { organizations(:hardrock) }
    let(:historical_slug) { "hardrock-original" }

    # Give the (currently "hardrock") org a prior slug, so the lookup goes through FriendlyId history.
    before { existing_organization.slugs.create!(slug: historical_slug) }

    # Regression for #2158: the scope must not `distinct`, or FriendlyId history's `find` (which orders
    # by friendly_id_slugs.id) raises PG::InvalidColumnReference against a SELECT DISTINCT.
    it "finds an organization by a historical slug without a DISTINCT/ORDER BY error" do
      expect { found }.not_to raise_error
      expect(found).to eq(existing_organization)
    end
  end
end
