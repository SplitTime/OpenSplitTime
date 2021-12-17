# frozen_string_literal: true

module LotterySimulations
  class Runner
    include ::Interactors::Errors

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
      simulation_run.start!
      validate_lottery_state

      if errors.present?
        fail_and_report_errors!
      else
        simulation_run.processing!

        requested_count.times do
          simulate_lottery
          save_simulation!
          delete_all_draws!
        end

        if errors.present?
          fail_and_report_errors!
        else
          simulation_run.finished!
        end
      end
    end

    private

    def fail_and_report_errors!
      simulation_run.update(status: :failed, error_message: errors.to_json)
    end

    attr_reader :simulation_run, :errors
    attr_accessor :simulation

    delegate :lottery, :requested_count, to: :simulation_run
    delegate :divisions, :draws, :entrants, :tickets, to: :lottery

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
    end

    def draw_random_tickets
      divisions.each do |division|
        slots_available = division.maximum_slots - division.draws.count
        undrawn_entrant_count = division.entrants.undrawn.count
        ticket_count_needed = [slots_available, undrawn_entrant_count].min

        ticket_count_needed.times { division.draw_ticket! }
      end
    end

    def validate_lottery_state
      errors << lottery_entrants_not_created_error unless entrants.exists?
      errors << lottery_tickets_not_generated_error unless tickets.exists?
      errors << lottery_draws_exist_error if draws.exists?
    end
  end
end
