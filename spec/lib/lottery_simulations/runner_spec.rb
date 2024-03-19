# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotterySimulations::Runner do
  subject { described_class.new(simulation_run) }
  let(:simulation_run) { create(:lottery_simulation_run, lottery: lottery, requested_count: 2) }
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

  describe "#perform!" do
    context "when the simulation run is valid" do
      before do
        lottery.delete_all_draws!
        subject.perform!
      end

      let(:expected_results) do
        {
          "Elses" => {
            "accepted" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
            "wait_list" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
          },
          "Never Ever Evers" => {
            "accepted" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
            "wait_list" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
          },
          "Veterans" => {
            "accepted" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
            "wait_list" => {
              "male" => anything,
              "male_entrant_ids" => anything,
              "female" => anything,
              "female_entrant_ids" => anything,
            },
          },
        }
      end

      it "creates the requested number of simulations" do
        expect(simulation_run.simulations.count).to eq(2)
      end

      it "sets sets expected values" do
        simulation_run.simulations.each do |simulation|
          expect(simulation.ticket_ids).to be_present

          # Mysteriously, expect(simulation.results).to eq(expected_results) does not work here
          lottery.divisions.each do |division|
            expect(simulation.results[division.name].keys).to eq(expected_results[division.name].keys)
            expect(simulation.results.dig(division.name, "accepted").keys).to match_array(expected_results.dig(division.name, "accepted").keys)
            expect(simulation.results.dig(division.name, "wait_list").keys).to match_array(expected_results.dig(division.name, "wait_list").keys)
          end
        end
      end
    end

    context "when draws already exist" do
      before { subject.perform! }
      it "does not create any simulations" do
        expect(simulation_run.simulations.count).to eq(0)
      end

      it "adds a descriptive error to the simulation run" do
        expect(simulation_run.error_message).to include("Lottery draws already exist")
      end
    end

    context "when tickets have not been generated" do
      before do
        lottery.delete_all_draws!
        lottery.tickets.delete_all
        subject.perform!
      end

      it "does not create any simulations" do
        expect(simulation_run.simulations.count).to eq(0)
      end

      it "adds a descriptive error to the simulation run" do
        expect(simulation_run.error_message).to include("Tickets have not yet been generated for this lottery")
      end
    end

    context "when entrants have not been created" do
      before do
        lottery.delete_all_draws!
        lottery.tickets.delete_all
        lottery.divisions.each { |division| division.entrants.delete_all }
        subject.perform!
      end

      it "does not create any simulations" do
        expect(simulation_run.simulations.count).to eq(0)
      end

      it "adds a descriptive error to the simulation run" do
        expect(simulation_run.error_message).to include("No lottery entrants exist")
      end
    end
  end
end
