require "rails_helper"

RSpec.describe LotteryEntrant, type: :model do
  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }
  it { is_expected.to capitalize_attribute(:city) }
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:city).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  describe "scopes" do
    let(:existing_scope) { division.entrants }
    let(:division) { LotteryDivision.find_by(name: division_name) }

    describe ".belonging_to_user" do
      let(:result) { existing_scope.belonging_to_user(user) }
      let(:user) { users(:fifth_user) }
      let(:division) { lottery_divisions(:lottery_division_0001) }
      let(:entrant_1) { lottery_entrants(:lottery_entrant_0001) }
      let(:entrant_2) { lottery_entrants(:lottery_entrant_0002) }
      let(:person) { people(:bruno_fadel) }

      context "when the user's avatar is the lottery entrant's person" do
        before do
          user.update(avatar: person)
          entrant_1.update(person: person)
        end

        it "returns a collection including that lottery entrant" do
          expect(result.count).to eq(1)
          expect(result).to include(entrant_1)
        end
      end

      context "when the user's email is the same as the lottery entrant's email" do
        before do
          entrant_1.update(email: user.email)
        end

        it "returns a collection including that lottery entrant" do
          expect(result.count).to eq(1)
          expect(result).to include(entrant_1)
        end
      end

      context "when email matches one entrant and person matches another" do
        before do
          user.update(avatar: person)
          entrant_1.update(person: person)
          entrant_2.update(email: user.email)
        end

        it "returns a collection including both entrants" do
          expect(result.count).to eq(2)
          expect(result).to include(entrant_1)
          expect(result).to include(entrant_2)
        end
      end

      context "when no matches are found" do
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".accepted" do
      let(:result) { existing_scope.accepted }

      context "when the existing scope includes entrants who have been accepted" do
        let(:division_name) { "Elses" }
        it "returns a collection of all accepted entrants" do
          expect(result.count).to eq(2)
          expect(result.map(&:first_name)).to match_array(%w[Denisha Melina])
        end
      end

      context "when the existing scope does not include entrants who have been accepted" do
        let(:division_name) { "Veterans" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".waitlisted" do
      let(:result) { existing_scope.waitlisted }

      context "when the existing scope includes entrants who have been waitlisted" do
        let(:division_name) { "Never Ever Evers" }
        it "returns a collection of all waitlisted entrants" do
          expect(result.count).to eq(2)
          expect(result.map(&:first_name)).to match_array(%w[Modesta Emeline])
        end
      end

      context "when the existing scope does not include entrants who have been waitlisted" do
        let(:division_name) { "Elses" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".drawn_beyond_waitlist" do
      let(:result) { existing_scope.drawn_beyond_waitlist }

      context "when the existing scope includes entrants who have been drawn beyond the waitlist maximum" do
        let(:division_name) { "Never Ever Evers" }
        before { division.draw_ticket! }

        it "returns a collection of all drawn_beyond_waitlist entrants" do
          expect(result.count).to eq(1)
          expect(result.map(&:first_name)).to eq(%w[Norris])
        end
      end

      context "when the existing scope does not include entrants who have been drawn beyond the waitlist maximum" do
        let(:division_name) { "Elses" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".drawn" do
      let(:result) { existing_scope.drawn }

      context "when the existing scope includes entrants who have been drawn" do
        let(:division_name) { "Never Ever Evers" }
        it "returns a collection of all relevant entrants" do
          expect(result.count).to eq(5)
          expect(result.map(&:first_name)).to match_array(%w[Mitsuko Jospeh Nenita Emeline Modesta])
        end
      end

      context "when the existing scope does not include entrants who have been drawn" do
        let(:division_name) { "Veterans" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".not_drawn" do
      let(:result) { existing_scope.not_drawn }

      context "when the existing scope includes entrants who have not been drawn" do
        let(:division_name) { "Elses" }
        it "returns a collection of all undrawn entrants" do
          expect(result.count).to eq(3)
          expect(result.map(&:first_name)).to match_array(%w[Shenika Abraham Maud])
        end
      end

      context "when the existing scope entrants have all been drawn" do
        let(:division_name) { "Never Ever Evers" }
        before { division.draw_ticket! }

        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end
  end

  describe "validations" do
    let(:new_entrant) do
      ::LotteryEntrant.new(division: division, first_name: first_name, last_name: last_name, birthdate: birthdate, gender: :male, number_of_tickets: 1)
    end
    let(:existing_entrant_lottery) { lotteries(:lottery_without_tickets) }
    let(:existing_entrant_division) { existing_entrant_lottery.divisions.find_by(name: "Slow People") }
    let(:same_lottery_other_division) { existing_entrant_lottery.divisions.find_by(name: "Fast People") }
    let(:existing_entrant) { existing_entrant_division.entrants.find_by(first_name: "Deb") }
    let(:different_lottery) { lotteries(:lottery_with_tickets_and_draws) }
    let(:different_lottery_division) { different_lottery.divisions.find_by(name: "Elses") }

    context "when the entrant key matches a key in the same division" do
      let(:division) { existing_entrant.division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is not valid" do
        expect(new_entrant).not_to be_valid
        expect(new_entrant.errors.full_messages).to include(/has already been entered/)
      end
    end

    context "when the entrant key matches a key in the same lottery but a different division" do
      let(:division) { same_lottery_other_division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is not valid" do
        expect(new_entrant).not_to be_valid
        expect(new_entrant.errors.full_messages).to include(/has already been entered/)
      end
    end

    context "when the entrant key matches a key in a different lottery" do
      let(:division) { different_lottery_division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is valid" do
        expect(new_entrant).to be_valid
      end
    end
  end

  describe "#draw_ticket!" do
    subject { lottery.entrants.find_by(last_name: "Crona") }
    let(:lottery) { lotteries(:lottery_without_tickets) }
    let(:execute_method) { subject.draw_ticket! }

    context "when the entrant has no tickets" do
      it "does not create a draw" do
        expect { execute_method }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(execute_method).to be_nil
      end
    end

    context "when the entrant has tickets that have not been drawn" do
      before { lottery.delete_and_insert_tickets! }
      it "creates a draw" do
        expect { execute_method }.to change { LotteryDraw.count }.by(1)
      end

      it "returns the draw" do
        expect(execute_method).to be_a(LotteryDraw)
      end
    end

    context "when the entrant has already been drawn" do
      before do
        lottery.delete_and_insert_tickets!
        lottery.draws.create(ticket: subject.tickets.first)
      end

      it "does not create a draw" do
        expect { execute_method }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(execute_method).to be_nil
      end
    end
  end

  describe "#drawn?" do
    subject { lottery.entrants.find_by(last_name: "Crona") }
    let(:lottery) { lotteries(:lottery_without_tickets) }
    let(:result) { subject.drawn? }

    context "when the entrant has no tickets" do
      it { expect(result).to eq(false) }
    end

    context "when the entrant has tickets that have not been drawn" do
      before { lottery.delete_and_insert_tickets! }
      it { expect(result).to eq(false) }
    end

    context "when the entrant has been drawn" do
      before do
        lottery.delete_and_insert_tickets!
        lottery.draws.create(ticket: subject.tickets.first)
      end

      it { expect(result).to eq(true) }
    end
  end
end
