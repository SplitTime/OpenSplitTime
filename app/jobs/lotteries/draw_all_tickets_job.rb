module Lotteries
  class DrawAllTicketsJob < ApplicationJob
    queue_as :default

    def perform(division)
      loop do
        break if division.full? || division.all_entrants_drawn?

        result = division.draw_ticket!
        break if result.nil?
      end

      broadcast_completion_flash(division)
    end

    private

    def broadcast_completion_flash(division)
      message = if division.full?
                  "All accepted and waitlisted slots have been filled for #{division.name}."
                else
                  "No more eligible entrants to draw for #{division.name}."
                end

      Turbo::StreamsChannel.broadcast_replace_to(
        division, :lottery_draws_admin,
        target: "flash",
        partial: "layouts/broadcast_flash",
        locals: { level: :success, message: message }
      )
    end
  end
end
