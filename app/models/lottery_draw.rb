class LotteryDraw < ApplicationRecord

  self.ignored_columns = ["lottery_id"]

  belongs_to :division, class_name: "LotteryDivision", foreign_key: :lottery_division_id, touch: true
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id
  has_one :lottery, through: :division

  scope :for_division, ->(division) { joins(ticket: :entrant).where(lottery_entrants: { division: division }) }
  scope :in_drawn_order, -> { reorder(created_at: :asc) }
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
  after_create_commit :broadcast_lottery_draw_created
  after_destroy_commit :broadcast_lottery_draw_destroyed

  delegate :entrant, :reference_number, to: :ticket
  delegate :first_name, :last_name, :gender, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           :bio, :flexible_geolocation, :full_name, to: :entrant, prefix: true
  delegate :number_of_tickets, to: :entrant

  def entrant_division_name
    entrant.division_name
  end

  def waitlist?
    position.present? && position > division.maximum_entries
  end

  private

  def add_position
    self.position = division.draws.prior_to_draw(self).count + 1
  end

  def broadcast_lottery_draw_created
    broadcast_render_later_to lottery, :lottery_draws, partial: "lotteries/draws/created", locals: { lottery_draw: self, lottery_division: division }
    broadcast_render_later_to division, :lottery_draws_admin, partial: "lotteries/draws/created_admin", locals: { lottery_draw: self, lottery_division: division }
  end

  def broadcast_lottery_draw_destroyed
    broadcast_render_to lottery, :lottery_draws, partial: "lotteries/draws/destroyed", locals: { lottery_draw: self, lottery_division: division }
    broadcast_render_to division, :lottery_draws_admin, partial: "lotteries/draws/destroyed_admin", locals: { lottery_draw: self, lottery_division: division }
  end
end
