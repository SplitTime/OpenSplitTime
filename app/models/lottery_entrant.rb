# frozen_string_literal: true

class LotteryEntrant < ApplicationRecord
  include Structpluck
  include StateCountrySyncable
  include Searchable
  include PersonalInfo
  include Delegable
  include CapitalizeAttributes

  has_person_name
  enum gender: [:male, :female]

  belongs_to :division, class_name: "LotteryDivision", foreign_key: "lottery_division_id"
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name, :city

  scope :drawn, -> { with_drawn_at_attribute.where.not(drawn_at: nil) }
  scope :undrawn, -> { with_drawn_at_attribute.where(drawn_at: nil) }
  scope :with_drawn_at_attribute, lambda {
    from(select("distinct on (lottery_tickets.lottery_entrant_id) lottery_entrants.*, lottery_draws.created_at as drawn_at")
           .left_joins(tickets: :draw).order("lottery_tickets.lottery_entrant_id, drawn_at"), :lottery_entrants)
  }
  scope :not_withdrawn, -> { where(withdrawn: [false, nil]) }
  scope :withdrawn, -> { where(withdrawn: true) }

  scope :ordered, -> { order(:drawn_at) }
  scope :ordered_for_export, -> { with_division_name.order("division_name, last_name") }
  scope :pre_selected, -> { where(pre_selected: true) }
  scope :with_division_name, -> { from(select("lottery_entrants.*, lottery_divisions.name as division_name").joins(:division), :lottery_entrants) }
  scope :with_policy_scope_attributes, lambda {
    from(select("lottery_entrants.*, organizations.concealed, organizations.id as organization_id").joins(division: {lottery: :organization}), :lottery_entrants)
  }

  validates_presence_of :first_name, :last_name, :gender, :birthdate, :number_of_tickets
  validates_with ::LotteryEntrantUniqueValidator

  def self.search(param)
    return all unless param.present?
    return none unless param.size > 2

    search_names_and_locations(param)
  end

  def self.search_default_none(param)
    return none unless param && param.size > 2

    search_names_and_locations(param)
  end

  delegate :lottery, to: :division
  delegate :organization, to: :lottery

  def delegated_division_name
    division.name
  end

  def draw_ticket!
    return if drawn?

    selected_ticket_index = rand(tickets.count)
    selected_ticket = tickets.offset(selected_ticket_index).first

    lottery.create_draw_for_ticket!(selected_ticket)
  end

  def drawn?
    tickets.joins(:draw).exists?
  end

  def to_s
    full_name
  end

  private

  # Needed to keep PersonalInfo#bio from breaking
  def current_age_approximate
    nil
  end
end
