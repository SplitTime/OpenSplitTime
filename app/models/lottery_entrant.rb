# frozen_string_literal: true

class LotteryEntrant < ApplicationRecord
  include CapitalizeAttributes, Delegable, PersonalInfo, Searchable, StateCountrySyncable, Structpluck

  has_person_name
  enum gender: [:male, :female]

  belongs_to :division, class_name: "LotteryDivision", foreign_key: "lottery_division_id"
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name, :city

  scope :drawn_and_ordered, -> { from(select("lottery_entrants.*, lottery_draws.created_at as drawn_at").joins(tickets: :draw).order(:drawn_at), :lottery_entrants) }
  scope :pre_selected, -> { where(pre_selected: true) }
  scope :with_division_name, -> { from(select("lottery_entrants.*, lottery_divisions.name as division_name").joins(:division), :lottery_entrants) }
  scope :with_policy_scope_attributes, -> do
    from(select("lottery_entrants.*, organizations.concealed, organizations.id as organization_id").joins(division: {lottery: :organization}), :lottery_entrants)
  end

  validates_presence_of :first_name, :last_name, :gender, :number_of_tickets

  def self.search(param)
    return all unless param
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
    tickets.joins(:draw).present?
  end
end
