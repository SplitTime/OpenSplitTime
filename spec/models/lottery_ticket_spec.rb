# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryTicket, type: :model do
  describe "drawn and undrawn scopes" do
    let(:existing_scope) { division.tickets }
    let(:division) { LotteryDivision.find_by(name: division_name) }
    let(:drawn_result) { existing_scope.drawn }
    let(:undrawn_result) { existing_scope.undrawn }

    context "when the existing scope includes drawn and undrawn tickets" do
      let(:division_name) { "Elses" }
      it "returns a collection of drawn and undrawn tickets respectively" do
        expect(drawn_result.count).to eq(2)
        expect(undrawn_result.count).to eq(6)
        expect(drawn_result.map { |ticket| ticket.entrant.first_name }).to match_array(["Denisha", "Melina"])
        expect(undrawn_result.map { |ticket| ticket.entrant.first_name }).to match_array(["Denisha", "Melina", "Melina", "Shenika", "Abraham", "Maud"])
      end
    end

    context "when the existing scope includes only undrawn tickets" do
      let(:division_name) { "Veterans" }
      it "returns a collection of drawn and undrawn tickets respectively" do
        expect(drawn_result).to be_empty
        expect(undrawn_result.count).to eq(7)
        expect(undrawn_result.map { |ticket| ticket.entrant.first_name }).to match_array(["Veola", "Veola", "Blythe", "Ivette", "Jerrold", "Jerrold", "Jerrold"])
      end
    end
  end
end
