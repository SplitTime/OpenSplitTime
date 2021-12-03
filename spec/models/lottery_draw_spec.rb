# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryDraw, type: :model do
  describe "callbacks" do
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
    let(:division) { lottery.divisions.find_by(name: division_name) }

    context "when the existing scope includes no drawn tickets" do
      let(:division_name) { "Veterans" }
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
end
