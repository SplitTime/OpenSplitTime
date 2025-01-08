require "rails_helper"

RSpec.describe HistoricalFactAutoReconciler do
  subject { described_class.new(parent) }
  let(:parent) { organizations(:hardrock) }
  let(:person_1) { people(:bruno_fadel) }
  let(:person_2) { people(:robby_gerlach) }
  let(:effort_1) { efforts(:hardrock_2016_vesta_borer) }
  let(:effort_2) { efforts(:hardrock_2016_lavon_paucek) }

  describe "#reconcile" do
    context "for historical facts that match with a result in an organization effort" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: effort_1.first_name, last_name: effort_1.last_name, gender: effort_1.gender, kind: :dnf, year: 2016) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: effort_2.first_name, last_name: effort_2.last_name, gender: effort_2.gender, kind: :finished, year: 2016) }

      it "assigns the fact to the person_id in the effort" do
        subject.reconcile

        expect(fact_1.reload.person_id).to eq(effort_1.person_id)
        expect(fact_2.reload.person_id).to eq(effort_2.person_id)
      end
    end

    context "for historical facts where a related fact is reconciled" do
      let!(:reconciled_fact) { create(:historical_fact, organization: parent, person: person, first_name: "Bruno", last_name: "Fadel", gender: "male", kind: :dnf, comments: "2016") }
      let!(:unreconciled_fact) { create(:historical_fact, organization: parent, person: nil, first_name: "Bruno", last_name: "Fadel", gender: "male", kind: :dnf, comments: "2017") }
      let(:person) { people(:bruno_fadel) }

      it "assigns the fact to the person_id of the related fact" do
        subject.reconcile

        expect(reconciled_fact.reload.person_id).to eq(person.id)
        expect(unreconciled_fact.reload.person_id).to eq(person.id)
      end
    end

    context "for historical facts that are definitive matches by name and birthdate with a person" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, birthdate: person_1.birthdate, kind: :dns, year: 2018) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, birthdate: person_2.birthdate, kind: :dns, year: 2019) }

      it "assigns the fact to the person" do
        subject.reconcile

        expect(fact_1.reload.person).to eq(person_1)
        expect(fact_2.reload.person).to eq(person_2)
      end
    end

    context "for historical facts that are definitive matches by name and phone number with a person" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, phone: person_1.phone, kind: :dns, year: 2018) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, phone: person_2.phone, kind: :dns, year: 2019) }

      it "assigns the fact to the person" do
        subject.reconcile

        expect(fact_1.reload.person).to eq(person_1)
        expect(fact_2.reload.person).to eq(person_2)
      end
    end

    context "for historical facts that are definitive matches by name and email with a person" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, email: person_1.email, kind: :dns, year: 2018) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, email: person_2.email, kind: :dns, year: 2019) }

      it "assigns the fact to the person" do
        subject.reconcile

        expect(fact_1.reload.person).to eq(person_1)
        expect(fact_2.reload.person).to eq(person_2)
      end
    end

    context "for historical facts that have no close matches with existing people" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: "Barney", last_name: "Fife", gender: "male", kind: :dns, year: 2018) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: "Andy", last_name: "Griffith", gender: "male", kind: :dns, year: 2019) }

      it "creates a new person and assigns the person to the fact" do
        expect { subject.reconcile }.to change(Person, :count).by(2)

        new_person_1 = Person.last(2).first
        new_person_2 = Person.last

        expect(fact_1.reload.person).to eq(new_person_1)
        expect(fact_2.reload.person).to eq(new_person_2)
      end
    end

    context "for historical facts that are ambiguous matches with one or more people" do
      let!(:fact_1) { create(:historical_fact, organization: parent, first_name: person_1.first_name, last_name: person_1.last_name, gender: person_1.gender, kind: :dns, year: 2018) }
      let!(:fact_2) { create(:historical_fact, organization: parent, first_name: person_2.first_name, last_name: person_2.last_name, gender: person_2.gender, kind: :dns, year: 2019) }

      it "does not create a new person and does not assign the facts to any person" do
        expect { subject.reconcile }.not_to change(Person, :count)

        expect(fact_1.reload.person).to be_nil
        expect(fact_2.reload.person).to be_nil
      end
    end
  end
end
