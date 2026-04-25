require "rails_helper"

RSpec.describe Person, type: :model do
  it_behaves_like "auditable"
  it_behaves_like "subscribable"
  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }
  it { is_expected.to capitalize_attribute(:city) }
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:city).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  describe "#initialize" do
    it "saves a generic factory-created record to the database" do
      expect { create(:person) }.to change(described_class, :count).by(1)
    end

    it "is valid when created with a first_name, a last_name, and a gender" do
      person = build_stubbed(:person)
      expect(person.first_name).to be_present
      expect(person.last_name).to be_present
      expect(person.gender).to be_present
      expect(person).to be_valid
    end

    it "is invalid without a first_name" do
      person = build_stubbed(:person, first_name: nil)
      expect(person).not_to be_valid
      expect(person.errors[:first_name]).to include("can't be blank")
    end

    it "is invalid without a last_name" do
      person = build_stubbed(:person, last_name: nil)
      expect(person).not_to be_valid
      expect(person.errors[:last_name]).to include("can't be blank")
    end

    it "is invalid without a gender" do
      person = build_stubbed(:person, gender: nil)
      expect(person).not_to be_valid
      expect(person.errors[:gender]).to include("can't be blank")
    end

    it "rejects invalid email" do
      bad_emails = %w[johnny@appleseed appleseed.com johnny@.com johnny]
      bad_emails.each do |email|
        person = described_class.new(email: email)
        expect(person).not_to be_valid
        expect(person.errors[:email]).to include("is invalid")
      end
    end

    it "permits valid email" do
      person = build_stubbed(:person, email: "user@example.com")
      expect(person).to be_valid
    end

    it "rejects implausible birthdates" do
      bad_birthdates = { "1880-01-01" => "can't be before 1900",
                         1.day.from_now => "can't be today or in the future" }
      bad_birthdates.each do |birthdate, error_message|
        person = described_class.new(birthdate: birthdate)
        expect(person).not_to be_valid
        expect(person.errors[:birthdate]).to include(error_message)
      end
    end

    it "permits plausible birthdates" do
      person = build_stubbed(:person, birthdate: "1977-01-01")
      expect(person).to be_valid
    end

    it "rejects invalid phone numbers" do
      bad_phone_numbers = %w[0+0 +++123 555+333]

      bad_phone_numbers.each do |phone|
        person = build_stubbed(:person, phone: phone)
        expect(person).not_to be_valid
        expect(person.errors[:phone]).to include("is invalid")
      end
    end

    it "accepts valid phone numbers" do
      good_phone_numbers = %w[3035551212 13035551212 +13035551212 ++442345678]

      good_phone_numbers.each do |phone|
        person = build_stubbed(:person, phone: phone)
        expect(person).to be_valid
      end
    end
  end

  describe "#current_age" do
    let(:person) { build_stubbed(:person, birthdate: 40.years.ago.to_date, hide_age: hide_age) }

    context "when hide_age is false" do
      let(:hide_age) { false }

      it "returns the age derived from birthdate" do
        expect(person.current_age).to eq(40)
      end
    end

    context "when hide_age is true" do
      let(:hide_age) { true }

      it "returns nil" do
        expect(person.current_age).to be_nil
      end

      it "returns the raw age via current_age_non_obscured" do
        expect(person.current_age_non_obscured).to eq(40)
      end

      it "still exposes the raw age via current_age_from_birthdate" do
        expect(person.current_age_from_birthdate).to eq(40)
      end
    end
  end

  describe "#current_age_conditionally_obscured" do
    let(:person) { build_stubbed(:person, birthdate: 40.years.ago.to_date, hide_age: hide_age) }
    let(:authorized_user) { instance_double(User) }
    let(:unauthorized_user) { instance_double(User) }

    before do
      allow(authorized_user).to receive(:authorized_to_edit?).with(person).and_return(true)
      allow(unauthorized_user).to receive(:authorized_to_edit?).with(person).and_return(false)
    end

    context "when hide_age is true" do
      let(:hide_age) { true }

      it "returns nil for unauthenticated and unauthorized viewers" do
        expect(person.current_age_conditionally_obscured(nil)).to be_nil
        expect(person.current_age_conditionally_obscured(unauthorized_user)).to be_nil
      end

      it "returns the raw age for an authorized viewer" do
        expect(person.current_age_conditionally_obscured(authorized_user)).to eq(40)
      end
    end

    context "when hide_age is false" do
      let(:hide_age) { false }

      it "returns the raw age regardless of viewer" do
        expect(person.current_age_conditionally_obscured(nil)).to eq(40)
        expect(person.current_age_conditionally_obscured(unauthorized_user)).to eq(40)
        expect(person.current_age_conditionally_obscured(authorized_user)).to eq(40)
      end
    end
  end

  describe "#display_full_name" do
    let(:person) { build_stubbed(:person, first_name: "Mark", last_name: "Oveson", obscure_name: obscure_name) }

    context "when obscure_name is false" do
      let(:obscure_name) { false }

      it "returns the real full name" do
        expect(person.display_full_name).to eq("Mark Oveson")
      end
    end

    context "when obscure_name is true" do
      let(:obscure_name) { true }

      it "returns initials" do
        expect(person.display_full_name).to eq("M. O.")
      end

      it "returns the real full name from display_full_name_non_obscured" do
        expect(person.display_full_name_non_obscured).to eq("Mark Oveson")
      end

      it "leaves full_name and first_name/last_name columns untouched" do
        expect(person.full_name).to eq("Mark Oveson")
        expect(person.first_name).to eq("Mark")
        expect(person.last_name).to eq("Oveson")
      end
    end
  end

  describe "#display_first_name" do
    let(:person) { build_stubbed(:person, first_name: "Mark", obscure_name: obscure_name) }

    context "when obscure_name is false" do
      let(:obscure_name) { false }

      it "returns the real first name" do
        expect(person.display_first_name).to eq("Mark")
      end
    end

    context "when obscure_name is true" do
      let(:obscure_name) { true }

      it "returns the first initial with a period" do
        expect(person.display_first_name).to eq("M.")
      end

      it "returns the real first name from display_first_name_non_obscured" do
        expect(person.display_first_name_non_obscured).to eq("Mark")
      end
    end
  end

  describe "slug generation" do
    let(:effort) { efforts(:hardrock_2014_finished_first) }

    it "uses the full name when obscure_name is false" do
      person = create(:person, first_name: "Mark", last_name: "Oveson", obscure_name: false)
      expect(person.slug).to start_with("mark-oveson")
    end

    it "uses initials when obscure_name is true on create" do
      person = create(:person, first_name: "Mark", last_name: "Oveson", obscure_name: true)
      expect(person.slug).not_to include("mark")
      expect(person.slug).not_to include("oveson")
      expect(person.slug).to start_with("m-o")
    end

    it "regenerates the slug and purges history when obscure_name is toggled on" do
      person = create(:person, first_name: "Mark", last_name: "Oveson", obscure_name: false)
      effort.update!(person_id: person.id, first_name: "Mark", last_name: "Oveson", slug: nil)
      original_person_slug = person.slug
      original_effort_slug = effort.reload.slug
      expect(original_effort_slug).to include("oveson")

      person.update!(obscure_name: true)

      expect(person.reload.slug).to start_with("m-o")
      expect(person.slug).not_to include("oveson")
      expect(described_class.friendly.exists?(original_person_slug)).to be(false)

      expect(effort.reload.slug).not_to include("oveson")
      expect(Effort.friendly.exists?(original_effort_slug)).to be(false)
    end

    it "regenerates the slug when obscure_name is toggled off, keeping history" do
      person = create(:person, first_name: "Mark", last_name: "Oveson", obscure_name: true)
      obscured_slug = person.slug

      person.update!(obscure_name: false)

      expect(person.reload.slug).to start_with("mark-oveson")
      expect(described_class.friendly.find(obscured_slug)).to eq(person)
    end
  end

  describe "cache busting when visibility flags change" do
    let(:person) { create(:person, hide_age: false, obscure_name: false) }
    let(:effort) { efforts(:hardrock_2014_finished_first) }

    before do
      effort.update_columns(person_id: person.id)
    end

    it "touches the event when hide_age changes so public caches invalidate" do
      original = effort.event.updated_at
      travel 1.second do
        person.update!(hide_age: true)
      end
      expect(effort.event.reload.updated_at).to be > original
    end

    it "touches the event when obscure_name changes so public caches invalidate" do
      original = effort.event.updated_at
      travel 1.second do
        person.update!(obscure_name: true)
      end
      expect(effort.event.reload.updated_at).to be > original
    end

    it "does not touch the event when unrelated attributes change" do
      original = effort.event.updated_at
      travel 1.second do
        person.update!(city: "Boulder")
      end
      expect(effort.event.reload.updated_at).to eq(original)
    end
  end
end
