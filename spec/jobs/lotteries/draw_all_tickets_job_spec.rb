require "rails_helper"

RSpec.describe Lotteries::DrawAllTicketsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(division) }

  let(:lottery) { division.lottery }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    division = LotteryDivision.find_by(name: "Elses")
    expect { described_class.perform_later(division) }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  context "when the division has eligible entrants" do
    let(:division) { LotteryDivision.find_by(name: "Elses") }

    before { lottery.delete_and_insert_tickets! }

    it "draws tickets until the division is full or all entrants are drawn" do
      expect { perform_enqueued_jobs { job } }.to(change { division.draws.count })
      expect(division.full? || division.all_entrants_drawn?).to eq(true)
    end
  end

  context "when the division is already full" do
    let(:division) { LotteryDivision.find_by(name: "Never Ever Evers") }

    it "does not create any new draws" do
      expect { perform_enqueued_jobs { job } }.not_to(change(LotteryDraw, :count))
    end
  end

  context "when all entrants have already been drawn" do
    let(:division) { LotteryDivision.find_by(name: "Elses") }

    before do
      lottery.delete_and_insert_tickets!
      division.entrants.not_drawn.count.times { division.draw_ticket! }
    end

    it "does not create any draws" do
      expect { perform_enqueued_jobs { job } }.not_to(change(LotteryDraw, :count))
    end
  end
end
