require "rails_helper"

RSpec.describe LotterySimulation, type: :model do
  describe "#build" do
    subject { build(:lottery_simulation, simulation_run: simulation_run) }

    let(:simulation_run) { create(:lottery_simulation_run, lottery: lottery, requested_count: 2) }
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

    describe "#build" do
      context "when draws exist" do
        before { subject.build }

        let(:expected_ticket_ids) do
          %i[lottery_ticket_0018 lottery_ticket_0003 lottery_ticket_0010 lottery_ticket_0017
             lottery_ticket_0009 lottery_ticket_0013 lottery_ticket_0006].map { |label| lottery_tickets(label).id }
        end
        let(:entrant_id) { ->(first, last) { LotteryEntrant.find_by!(first_name: first, last_name: last).id } }
        let(:expected_results) do
          {
            "Elses" => {
              "accepted" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 2,
                "female_entrant_ids" => contain_exactly(entrant_id["Denisha", "Carter"], entrant_id["Melina", "Conroy"]),
              },
              "wait_list" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
            },
            "Never Ever Evers" => {
              "accepted" => {
                "male" => 1,
                "male_entrant_ids" => [entrant_id["Nenita", "Heaney"]],
                "female" => 2,
                "female_entrant_ids" => contain_exactly(entrant_id["Jospeh", "Barrows"], entrant_id["Mitsuko", "Wilkinson"]),
              },
              "wait_list" => {
                "male" => 1,
                "male_entrant_ids" => [entrant_id["Emeline", "Runolfsson"]],
                "female" => 1,
                "female_entrant_ids" => [entrant_id["Modesta", "Raynor"]],
              },
            },
            "Veterans" => {
              "accepted" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
              "wait_list" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => []
              },
            },
          }
        end

        it "sets the ticket ids and result" do
          expect(subject.ticket_ids).to eq(expected_ticket_ids)
          expect(subject.results).to match(expected_results)
        end
      end

      context "when no draws exist" do
        before do
          lottery.delete_all_draws!
          subject.build
        end

        let(:expected_ticket_ids) { [] }
        let(:expected_results) do
          {
            "Elses" => {
              "accepted" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
              "wait_list" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
            },
            "Never Ever Evers" => {
              "accepted" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
              "wait_list" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
            },
            "Veterans" => {
              "accepted" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => [],
              },
              "wait_list" => {
                "male" => 0,
                "male_entrant_ids" => [],
                "female" => 0,
                "female_entrant_ids" => []
              },
            },
          }
        end

        it "sets the ticket ids and result" do
          expect(subject.ticket_ids).to eq(expected_ticket_ids)
          expect(subject.results).to eq(expected_results)
        end
      end
    end
  end
end
