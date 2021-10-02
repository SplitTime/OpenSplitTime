# frozen_string_literal: true

class LotteryDivision < ApplicationRecord
  include CapitalizeAttributes

  belongs_to :lottery, touch: true
  has_many :entrants, class_name: "LotteryEntrant", dependent: :destroy
  has_many :tickets, through: :entrants

  strip_attributes collapse_spaces: true
  capitalize_attributes :name

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :lottery

  def draw_ticket!
    drawn_entrants = entrants.joins(tickets: :draw)
    eligible_tickets = tickets.where.not(lottery_entrant_id: drawn_entrants)
    drawn_ticket_index = rand(eligible_tickets.count)
    drawn_ticket = eligible_tickets.offset(drawn_ticket_index).first

    lottery.draws.create(ticket: drawn_ticket) if drawn_ticket.present?
  end

  def ordered_drawn_entrants
    entrants.drawn_and_ordered
  end

  def winning_entrants
    ordered_drawn_entrants.limit(maximum_entries)
  end

  def wait_list_entrants
    ordered_drawn_entrants.offset(maximum_entries - 1).limit(maximum_wait_list)
  end
end
