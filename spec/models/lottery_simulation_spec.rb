# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotterySimulation, type: :model do
  describe "#build" do
    let(:subject) { build(:lottery_simulation, simulation_run: simulation_run) }
    let(:simulation_run) { create(:lottery_simulation_run, lottery: lottery, requested_count: 2) }
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

    describe "#build" do
      context "when draws exist" do
        before { subject.build }

        let(:expected_ticket_ids) { [18, 3, 10, 17, 9, 13, 6] }
        let(:expected_results) do
          [{"division_name"=>"Elses",
            "accepted"=>{"male"=>0, "female"=>2},
            "wait_list"=>{"male"=>0, "female"=>0}},
           {"division_name"=>"Never Ever Evers",
            "accepted"=>{"male"=>1, "female"=>2},
            "wait_list"=>{"male"=>1, "female"=>1}},
           {"division_name"=>"Veterans",
            "accepted"=>{"male"=>0, "female"=>0},
            "wait_list"=>{"male"=>0, "female"=>0}}]
        end

        it "sets the ticket ids and result" do
          expect(subject.ticket_ids).to eq(expected_ticket_ids)
          expect(subject.results).to eq(expected_results)
        end
      end

      context "when no draws exist" do
        before do
          lottery.delete_all_draws!
          subject.build
        end

        let(:expected_ticket_ids) { [] }
        let(:expected_results) do
          [{"division_name"=>"Elses",
            "accepted"=>{"male"=>0, "female"=>0},
            "wait_list"=>{"male"=>0, "female"=>0}},
           {"division_name"=>"Never Ever Evers",
            "accepted"=>{"male"=>0, "female"=>0},
            "wait_list"=>{"male"=>0, "female"=>0}},
           {"division_name"=>"Veterans",
            "accepted"=>{"male"=>0, "female"=>0},
            "wait_list"=>{"male"=>0, "female"=>0}}]
        end

        it "sets the ticket ids and result" do
          expect(subject.ticket_ids).to eq(expected_ticket_ids)
          expect(subject.results).to eq(expected_results)
        end
      end
    end
  end
end
