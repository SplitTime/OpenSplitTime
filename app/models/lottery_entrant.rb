# frozen_string_literal: true

class LotteryEntrant < ApplicationRecord
  include CapitalizeAttributes, PersonalInfo, Searchable, StateCountrySyncable, Structpluck

  has_person_name
  enum gender: [:male, :female]

  belongs_to :division, class_name: "LotteryDivision", foreign_key: "lottery_division_id"
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name, :city

  scope :with_division_name, -> { from(select("lottery_entrants.*, lottery_divisions.name as division_name").joins(:division), :lottery_entrants) }
  scope :drawn_and_ordered, -> { from(select("lottery_entrants.*, lottery_draws.created_at as drawn_at").joins(tickets: :draw).order(:drawn_at), :lottery_entrants) }

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

  def delegated_division_name
    division.name
  end
end
