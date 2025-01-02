class LotteryTicket < ApplicationRecord
  include PgSearch::Model

  belongs_to :lottery
  belongs_to :entrant, class_name: "LotteryEntrant", foreign_key: "lottery_entrant_id"
  has_one :draw, class_name: "LotteryDraw", dependent: :destroy

  scope :drawn, -> { left_joins(:draw).where.not(lottery_draws: { lottery_ticket_id: nil }) }
  scope :not_drawn, -> { left_joins(:draw).where(lottery_draws: { lottery_ticket_id: nil }) }
  scope :ordered_by_reference_number, -> { order(reference_number: :asc) }
  scope :with_sortable_entrant_attributes, lambda {
    from(select("lottery_tickets.*, lottery_divisions.name as division_name, first_name, last_name, gender, city, state_code, state_name, country_code, country_name")
           .joins(entrant: :division), :lottery_tickets)
  }

  pg_search_scope :search_against_entrants,
                  against: :reference_number,
                  associated_against: {
                    entrant: [:first_name, :last_name]
                  }

  def self.search(param)
    return none unless param.present? && param.size > 2

    search_against_entrants(param)
  end

  delegate :first_name, :last_name, :gender, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           :bio, :flexible_geolocation, :full_name, to: :entrant, prefix: true

  def drawn?
    draw.present?
  end

  def entrant_division_name
    entrant.division_name
  end
end
