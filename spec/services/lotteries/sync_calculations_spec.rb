require "rails_helper"

RSpec.describe Lotteries::SyncCalculations do
  subject { described_class.new(lottery) }
  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:organization) { lottery.organization }

  context "when the lottery does not have a calculation_class" do
    it "raises an error" do
      expect { subject.perform! }.to raise_error ArgumentError, /Lottery does not have a calculation class/
    end
  end

  context "when the lottery calculation_class does not exist" do
    before { lottery.update(calculation_class: "nonexistent") }

    it "raises an error" do
      expect { subject.perform! }.to raise_error ArgumentError, /Calculation class does not exist/
    end
  end

  context "when the lottery calculation_class is valid" do
    before { lottery.update(calculation_class: "Hardrock2025") }

    context "when division names do not match" do
      it "raises an error" do
        expect { subject.perform! }.to raise_error ArgumentError, /Calculated division names were not all found/
      end
    end

    context "when division names match" do
      let(:division_names) { ["Female Finishers", "Female Nevers", "Male Finishers", "Male Nevers"] }

      before do
        lottery.divisions.each(&:destroy)
        division_names.each { |name| lottery.divisions.create(name: name, maximum_entries: 5, maximum_wait_list: 5) }
      end

      context "when calculations are not all reconciled" do
        let(:fact) { organization.historical_facts.find_by(kind: :lottery_application, person: person) }
        let(:person) { people(:antony_grady) }
        before { fact.update!(person: nil) }

        it "raises an error" do
          expect { subject.perform! }.to raise_error ArgumentError, /Some historical facts underlying the lottery calculation are not reconciled/
        end
      end

      context "when calculations are all reconciled" do
        it "does not raise an error" do
          expect { subject.perform! }.not_to raise_error
        end

        it "creates lottery entrants" do
          expect { subject.perform! }.to change { LotteryEntrant.count }.by(10)
        end

        context "when lottery entrants exist and have a matching person_id" do
          let(:division) { lottery.divisions.find_by(name: "Female Finishers") }
          let(:person) { people(:antony_grady) }
          let!(:entrant) do
            division.entrants.create!(
              person: person,
              first_name: "Old Name",
              last_name: person.last_name,
              gender: person.gender,
              number_of_tickets: 1,
            )
          end

          it "updates lottery entrants using calculated data" do
            subject.perform!

            expect(entrant.reload).to have_attributes(first_name: "Antony", number_of_tickets: 2)
          end
        end

        context "when lottery entrants exist and do not have a matching person_id" do
          let(:division) { lottery.divisions.find_by(name: "Female Finishers") }
          let(:person) { people(:bruno_fadel) }
          let!(:entrant) do
            division.entrants.create!(
              person: person,
              first_name: person.first_name,
              last_name: person.last_name,
              gender: person.gender,
              number_of_tickets: 1,
            )
          end

          it "deletes the entrants" do
            expect(division.entrants).to include(entrant)

            subject.perform!

            expect(division.entrants).not_to include(entrant)
          end
        end
      end
    end
  end
end
