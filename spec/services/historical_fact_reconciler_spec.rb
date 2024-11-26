# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricalFactReconciler do
  subject { described_class.new(parent, personal_info_hash: personal_info_hash, person_id: person_id) }
  let(:parent) { organizations(:hardrock) }
  let(:personal_info_hash) { fact_1.personal_info_hash }
  let(:person_id) { person.id }
  let(:person) { people(:bruno_fadel) }
  let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person.first_name, last_name: person.last_name, gender: person.gender, email: "bruno@enchanted.com", kind: :dnf, comments: "2016") }
  let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person.first_name, last_name: person.last_name, gender: person.gender, phone: "3035551212", kind: :finished, comments: "2016") }

  describe "#reconcile" do
    context "when the person exists" do
      it "assigns the relevant facts to the person_id in the effort" do
        expect(fact_1.reload.person_id).to be_nil
        expect(fact_2.reload.person_id).to be_nil

        subject.reconcile

        expect(fact_1.reload.person_id).to eq(person_id)
        expect(fact_2.reload.person_id).to eq(person_id)
      end

      it "contributes email and phone to the matched person" do
        expect(person.email).to be_nil
        expect(person.phone).to be_nil

        subject.reconcile
        person.reload

        expect(person.email).to eq("bruno@enchanted.com")
        expect(person.phone).to eq("3035551212")
      end
    end

    context "when the person does not exist" do
      let(:person_id) { 0 }

      it "returns without assigning a person_id" do
        subject.reconcile

        expect(fact_1.reload.person_id).to be_nil
        expect(fact_2.reload.person_id).to be_nil
      end
    end

    context "when the person_id is 'new'" do
      let(:person_id) { "new" }
      # New person slug is colliding with existing person slug and causing the spec to fail
      before { person.update(slug: "bruno-fadel-1") }

      it "creates a new Person record and backfills information from historical facts" do
        expect { subject.reconcile }.to change(Person, :count).by(1)
      end
    end
  end
end
