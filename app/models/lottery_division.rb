# frozen_string_literal: true

class LotteryDivision < ApplicationRecord
  include CapitalizeAttributes, Delegable

  belongs_to :lottery, touch: true
  has_many :entrants, class_name: "LotteryEntrant", dependent: :destroy
  has_many :tickets, through: :entrants

  strip_attributes collapse_spaces: true
  capitalize_attributes :name

  validates_presence_of :maximum_entries, :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :lottery

  scope :with_policy_scope_attributes, -> do
    from(select("lottery_divisions.*, organizations.concealed, organizations.id as organization_id").joins(lottery: :organization), :lottery_divisions)
  end

  delegate :organization, to: :lottery

  def draw_ticket!
    drawn_entrants = entrants.joins(tickets: :draw)
    eligible_tickets = tickets.where.not(lottery_entrant_id: drawn_entrants)
    drawn_ticket_index = rand(eligible_tickets.count)
    drawn_ticket = eligible_tickets.offset(drawn_ticket_index).first

    lottery.draw_ticket!(drawn_ticket)
  end

  def draws
    lottery.draws.for_division(self)
  end

  def reverse_loaded_draws
    loaded_draws.reorder(created_at: :desc)
  end

  def wait_list_entrants
    ordered_drawn_entrants.offset(maximum_entries).limit(maximum_wait_list)
  end

  def winning_entrants
    ordered_drawn_entrants.limit(maximum_entries)
  end

  private

  def loaded_draws
    draws.includes(ticket: :entrant)
  end

  def ordered_drawn_entrants
    entrants.drawn_and_ordered
  end
end
