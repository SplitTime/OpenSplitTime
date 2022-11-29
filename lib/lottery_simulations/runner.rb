# frozen_string_literal: true

module LotterySimulations
  class Runner
    include ::Interactors::Errors

    UPDATE_INTERVAL = 5

    # @param [::LotterySimulationRun] simulation_run
    # @return [Integer]
    def self.perform!(simulation_run)
      new(simulation_run).perform!
    end

    def initialize(simulation_run)
      @simulation_run = simulation_run
      @simulation = nil
      @errors = []
    end

    # @return [Integer]
    def perform!
      start_simulation_run
      validate_lottery_state
      run_simulations if errors.empty?
      fail_and_report_errors! if errors.present?
      requested_count
    end

    private

    attr_reader :simulation_run, :errors
    attr_accessor :simulation

    delegate :lottery, :requested_count, to: :simulation_run
    delegate :divisions, :draws, :entrants, :tickets, to: :lottery

    def start_simulation_run
      simulation_run.start!
      simulation_run.set_context!
    end

    def run_simulations
      simulation_run.processing!

      requested_count.times do
        simulate_lottery
        save_simulation!
        delete_all_draws!
      end

      simulation_run.finished! if errors.empty?
    end

    def fail_and_report_errors!
      simulation_run.update(status: :failed, error_message: errors.to_json)
    end

    def simulate_lottery
      simulate_lottery_draws!
      build_simulation_from_draws
    end

    def save_simulation!
      if simulation.save
        simulation_run.increment(:success_count)
      else
        simulation_run.increment(:failure_count)
        errors << simulation.errors.full_messages
      end

      simulation_run.set_elapsed_time!
    end

    def delete_all_draws!
      lottery.delete_all_draws!
    end

    def simulate_lottery_draws!
      draw_pre_selected_entrants
      draw_random_tickets
    end

    def build_simulation_from_draws
      self.simulation = simulation_run.simulations.new
      simulation.build
    end

    def draw_pre_selected_entrants
      lottery.entrants.pre_selected.each(&:draw_ticket!)
      simulation_run.set_elapsed_time!
    end

    def draw_random_tickets
      divisions.each do |division|
        slots_available = division.maximum_slots - division.draws.count
        undrawn_entrant_count = division.entrants.undrawn.count
        ticket_count_needed = [slots_available, undrawn_entrant_count].min

        ticket_count_needed.times do |i|
          division.draw_ticket!
          simulation_run.set_elapsed_time! if i % UPDATE_INTERVAL == 0
        end
      end
    end

    def validate_lottery_state
      errors << lottery_entrants_not_created_error unless entrants.exists?
      errors << lottery_tickets_not_generated_error unless tickets.exists?
      errors << lottery_draws_exist_error if draws.exists?
    end
  end
end
