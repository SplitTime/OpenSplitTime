require "rails_helper"

RSpec.describe LotteryDraw, type: :model do
  describe "callbacks" do
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
    let(:division) { lottery.divisions.find_by(name: division_name) }
    let(:division_name) { "Veterans" }

    describe "set position" do
      context "when the existing scope includes no drawn tickets" do
        it "sets position of a new draw to 1" do
          draw = division.draw_ticket!
          expect(draw.position).to eq(1)
        end
      end

      context "when the existing scope includes 2 drawn tickets" do
        let(:division_name) { "Elses" }
        it "sets position of a new draw to 3" do
          draw = division.draw_ticket!
          expect(draw.position).to eq(3)
        end
      end

      context "when the existing scope includes several drawn tickets" do
        let(:division_name) { "Never Ever Evers" }
        it "sets position of a new draw to one greater" do
          draw = division.draw_ticket!
          expect(draw.position).to eq(6)
        end
      end
    end

    describe "manage drawn_at for the entrant" do
      let(:division_name) { "Veterans" }
      let(:entrant) { division.entrants.first }

      context "when a draw is created for an entrant that has no existing drawn_at" do
        it "sets drawn_at to the created_at time of the draw" do
          expect(entrant.reload.drawn_at).to be_nil
          draw = entrant.draw_ticket!
          expect(entrant.reload.drawn_at).to eq(draw.created_at)
        end
      end

      context "when a draw is created for an entrant that has an existing drawn_at" do
        before { entrant.update(drawn_at: Time.zone.now) }

        it "does not change drawn_at" do
          current_drawn_at = entrant.drawn_at
          entrant.draw_ticket!
          expect(entrant.drawn_at).to eq(current_drawn_at)
        end
      end

      context "when a draw is destroyed for an entrant that has no other draw" do
        let!(:draw) { entrant.draw_ticket! }

        it "sets drawn_at to nil" do
          expect(entrant.reload.drawn_at).to eq(draw.created_at)
          draw.destroy!
          expect(entrant.reload.drawn_at).to be_nil
        end
      end

      context "when a draw is destroyed for an entrant that has another draw" do
        let(:entrant) { division.entrants.find_by(last_name: "Treutel") }
        let!(:original_draw) { entrant.draw_ticket! }
        let(:additional_drawn_ticket) { entrant.tickets.not_drawn.first }
        let!(:additional_draw) { LotteryDraw.create!(division: division, ticket: additional_drawn_ticket) }

        before { entrant.update(drawn_at: additional_draw.created_at) }

        it "sets drawn_at to the original draw created_at" do
          expect(entrant.reload.drawn_at).to eq(additional_draw.created_at)
          additional_draw.destroy!
          expect(entrant.reload.drawn_at).to eq(original_draw.created_at)
        end
      end
    end
  end
end
