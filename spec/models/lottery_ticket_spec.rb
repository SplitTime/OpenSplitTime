# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryTicket, type: :model do
  describe "scopes" do
    let(:existing_scope) { division.tickets }
    let(:division) { LotteryDivision.find_by(name: division_name) }

    describe ".drawn" do
      let(:result) { existing_scope.drawn }

      context "when the existing scope includes drawn and undrawn tickets" do
        let(:division_name) { "Elses" }
        it "returns a collection of drawn tickets" do
          expect(result.count).to eq(2)
          expect(result.map { |ticket| ticket.entrant.first_name }).to match_array(%w[Denisha Melina])
        end
      end

      context "when the existing scope includes only undrawn tickets" do
        let(:division_name) { "Veterans" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".not_drawn" do
      let(:result) { existing_scope.not_drawn }

      context "when the existing scope includes drawn and undrawn tickets" do
        let(:division_name) { "Elses" }
        it "returns a collection of not_drawn tickets" do
          expect(result.count).to eq(6)
          expect(result.map { |ticket| ticket.entrant.first_name }).to match_array(%w[Denisha Melina Melina Shenika Abraham Maud])
        end
      end

      context "when the existing scope includes only drawn tickets" do
        let(:division_name) { "Never Ever Evers" }
        before { division.tickets.not_drawn.each(&:destroy) }

        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end
  end
end
