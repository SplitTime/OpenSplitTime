# frozen_string_literal: true

class LotteryTicket < ApplicationRecord
  include PgSearch::Model

  belongs_to :lottery
  belongs_to :entrant, class_name: "LotteryEntrant", foreign_key: "lottery_entrant_id"
  has_one :draw, class_name: "LotteryDraw", dependent: :destroy

  scope :with_sortable_entrant_attributes, -> do
    from(select("lottery_tickets.*, lottery_divisions.name as division_name, first_name, last_name, gender, city, state_code, state_name, country_code, country_name")
           .joins(entrant: :division), :lottery_tickets)
  end
  scope :drawn, -> { from(select("lottery_tickets.*, lottery_draws.created_at as drawn_at").joins(:draw), :lottery_tickets) }

  pg_search_scope :search_against_entrants,
                  against: :reference_number,
                  associated_against: {
                    entrant: [:first_name, :last_name, :city, :state_name, :country_name]
                  },
                  using: {
                    tsearch: { prefix: true },
                    dmetaphone: {}
                  }

  def self.search(param)
    return all unless param
    return none unless param.size > 2

    search_against_entrants(param)
  end

  delegate :first_name, :last_name, :gender, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           :bio, :flexible_geolocation, :full_name, to: :entrant, prefix: true

  def entrant_division_name
    entrant.delegated_division_name
  end
end
