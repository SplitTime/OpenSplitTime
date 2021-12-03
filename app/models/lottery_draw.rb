# frozen_string_literal: true

class LotteryDraw < ApplicationRecord
  belongs_to :lottery
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id

  scope :for_division, ->(division) { joins(ticket: :entrant).where(lottery_entrants: { division: division }) }
  scope :include_entrant_and_division, -> { includes(ticket: { entrant: :division }) }
  scope :prior_to_draw, ->(draw) { where("lottery_draws.created_at < ?", draw.created_at) }
  scope :most_recent_first, -> { reorder(created_at: :desc) }
  scope :with_entrant_and_ticket, -> { includes(ticket: :entrant) }
  scope :with_sortable_entrant_attributes, lambda {
    from(select("lottery_draws.*, lottery_divisions.name as division_name, first_name, last_name, gender, birthdate, city, state_code, state_name, country_code, country_name")
           .joins(ticket: { entrant: :division }), :lottery_draws)
  }

  validates_uniqueness_of :lottery_ticket_id

  before_create :add_position
  after_create_commit :broadcast_lottery_draw_create
  after_destroy_commit :broadcast_lottery_draw_destroy

  delegate :entrant, :reference_number, to: :ticket
  delegate :first_name, :last_name, :gender, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           :bio, :flexible_geolocation, :full_name, to: :entrant, prefix: true
  delegate :division, :number_of_tickets, to: :entrant

  def entrant_division_name
    entrant.delegated_division_name
  end

  def waitlist?
    position.present? && position > division.maximum_entries
  end

  private

  def add_position
    self.position = division.draws.prior_to_draw(self).count + 1
  end

  def broadcast_lottery_draw_create
    broadcast_prepend_to lottery, :lottery_draws, target: "lottery_draws"
    broadcast_prepend_to division, :lottery_draws, target: "lottery_draws_lottery_division_#{division.id}", partial: "lottery_draws/lottery_draw_admin"
  end

  def broadcast_lottery_draw_destroy
    broadcast_remove_to lottery, :lottery_draws
    broadcast_remove_to division, :lottery_draws
  end
end
