# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricalFactAutoReconciler do
  subject { described_class.new(parent) }
  let(:parent) { organizations(:hardrock) }
  let(:person_1) { people(:bruno_fadel) }
  let(:person_2) { people(:robby_gerlach) }

  describe "#reconcile" do
    context "for historical facts that are definitive matches with a person" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, birthdate: person_1.birthdate, kind: :dns, comments: "2018") }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, birthdate: person_2.birthdate, kind: :dns, comments: "2019") }

      it "assigns the fact to the person" do
        subject.reconcile

        expect(fact_1.reload.person).to eq(person_1)
        expect(fact_2.reload.person).to eq(person_2)
      end
    end

    context "for historical facts that are exact but not definitive matches with a person" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, state_code: person_1.state_code, kind: :dns, comments: "2018") }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, state_code: person_2.state_code, kind: :dns, comments: "2019") }

      it "assigns the fact to the person" do
        subject.reconcile

        expect(fact_1.reload.person).to eq(person_1)
        expect(fact_2.reload.person).to eq(person_2)
      end
    end

    context "for historical facts that have no close matches with existing people" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: "Barney", last_name: "Fife", gender: "male", kind: :dns, comments: "2018") }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: "Andy", last_name: "Griffith", gender: "male", kind: :dns, comments: "2019") }

      it "creates a new person and assigns the person to the fact" do
        expect { subject.reconcile }.to change(Person, :count).by(2)

        new_person_1 = Person.last(2).first
        new_person_2 = Person.last

        expect(fact_1.reload.person).to eq(new_person_1)
        expect(fact_2.reload.person).to eq(new_person_2)
      end
    end

    context "for historical facts that are ambiguous matches with one or more people" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, kind: :dns, comments: "2018") }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, kind: :dns, comments: "2019") }

      it "does not create a new person and does not assign the facts to any person" do
        expect { subject.reconcile }.not_to change(Person, :count)

        expect(fact_1.reload.person).to be_nil
        expect(fact_2.reload.person).to be_nil
      end
    end
  end
end
