# frozen_string_literal: true

class LotteryDraw < ApplicationRecord
  after_create_commit :broadcast_lottery_draw

  belongs_to :lottery
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id

  scope :for_division, ->(division) { joins(ticket: :entrant).where(lottery_entrants: {division: division}) }
  scope :with_sortable_entrant_attributes, -> do
    from(select("lottery_draws.*, lottery_divisions.name as division_name, first_name, last_name, gender, birthdate, city, state_code, state_name, country_code, country_name")
           .joins(ticket: {entrant: :division}), :lottery_draws)
  end

  delegate :entrant, to: :ticket
  delegate :first_name, :last_name, :gender, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           :bio, :flexible_geolocation, :full_name, to: :entrant, prefix: true
  delegate :division, to: :entrant

  def entrant_division_name
    entrant.delegated_division_name
  end

  private

  def broadcast_lottery_draw
    broadcast_prepend_to lottery, :lottery_draws, target: "lottery_draws"
    broadcast_prepend_to division, :lottery_draws, target: "lottery_draws_lottery_division_#{division.id}", partial: "lottery_draws/lottery_draw_admin"
  end
end
