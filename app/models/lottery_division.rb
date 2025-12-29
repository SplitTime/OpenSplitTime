class LotteryDivision < ApplicationRecord
  include Delegable
  include CapitalizeAttributes

  belongs_to :lottery, touch: true
  has_many :draws, class_name: "LotteryDraw", dependent: :destroy
  has_many :entrants, class_name: "LotteryEntrant", dependent: :destroy
  has_many :tickets, through: :entrants

  strip_attributes collapse_spaces: true
  capitalize_attributes :name

  validates_presence_of :maximum_entries, :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :lottery

  scope :ordered_by_name, -> { order(:name) }
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
    # Start with LotteryTicket.where(lottery_division_id: id) instead of using tickets.where(...).
    # Starting with #tickets results in a query that relies on lottery_entrants.lottery_division_id,
    # which doesn't take advantage of the index on lottery_tickets (lottery_division_id, reference_number)
    eligible_tickets = LotteryTicket.joins(:entrant).where(lottery_tickets: { lottery_division_id: id }, lottery_entrants: { drawn_at: nil, withdrawn: [false, nil] })
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
