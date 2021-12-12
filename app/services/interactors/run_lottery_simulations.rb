# frozen_string_literal: true

module Interactors
  class RunLotterySimulations
    def self.perform!(simulation_run)
      new(simulation_run).perform!
    end

    def initialize(simulation_run)
      @simulation_run = simulation_run
      @simulation = nil
      @errors = []
    end

    def perform!
      simulation_run.start!
      simulation_run.processing!

      requested_count.times do
        simulate_lottery
        save_simulation!
      end
    end

    private

    attr_reader :simulation_run, :errors
    attr_accessor :simulation

    delegate :lottery, :requested_count, to: :simulation_run
    delegate :divisions, to: :lottery

    def simulate_lottery
      ActiveRecord::Base.transaction do
        simulate_lottery_draws!
        build_simulation_from_draws
      ensure
        raise ActiveRecord::Rollback
      end
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
  end
end
