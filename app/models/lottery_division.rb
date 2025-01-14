class LotteryDivision < ApplicationRecord
  include Delegable
  include CapitalizeAttributes

  belongs_to :lottery
  has_many :draws, class_name: "LotteryDraw", dependent: :destroy
  has_many :entrants, class_name: "LotteryEntrant", dependent: :destroy
  has_many :tickets, through: :entrants

  strip_attributes collapse_spaces: true
  capitalize_attributes :name

  validates_presence_of :maximum_entries, :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :lottery

  scope :ordered_by_name, -> { order(:name) }
  scope :with_drawn_tickets_count, -> {
    from(left_joins(:draws)
           .select("lottery_divisions.*, SUM(case when lottery_draws.lottery_division_id = lottery_divisions.id then 1 else 0 end) AS drawn_tickets_count")
           .group("lottery_divisions.id"), :lottery_divisions)
  }

  scope :with_policy_scope_attributes, lambda {
    from(select("lottery_divisions.*, organizations.concealed, organizations.id as organization_id").joins(lottery: :organization), :lottery_divisions)
  }

  delegate :organization, to: :lottery

  def accepted_entrants
    entrants.accepted.ordered
  end

  def all_entrants_drawn?
    entrants.not_drawn.empty?
  end

  def create_draw_for_ticket!(ticket)
    return if ticket.nil? || ticket.drawn?

    draws.create!(ticket: ticket)
  end

  def draw_ticket!
    drawn_entrants = entrants.drawn
    eligible_tickets = tickets.where.not(lottery_entrant_id: drawn_entrants)
    selected_ticket_index = rand(eligible_tickets.count)
    selected_ticket = eligible_tickets.ordered_by_reference_number.offset(selected_ticket_index).first

    create_draw_for_ticket!(selected_ticket)
  end

  def full?
    entrants.drawn.count >= maximum_slots
  end

  def maximum_slots
    maximum_entries + maximum_wait_list
  end

  def waitlisted_entrants
    entrants.waitlisted.ordered
  end

  def withdrawn_entrants
    entrants.withdrawn
  end
end
