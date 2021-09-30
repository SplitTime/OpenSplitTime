# frozen_string_literal: true

class LotteryEntrant < ApplicationRecord
  include CapitalizeAttributes, PersonalInfo, Searchable, StateCountrySyncable

  has_person_name
  enum gender: [:male, :female]

  belongs_to :lottery_division

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name, :city

  scope :with_division_name, -> { from(select("lottery_entrants.*, lottery_divisions.name as division_name").joins(:lottery_division), :lottery_entrants) }

  validates_presence_of :first_name, :last_name, :gender, :number_of_tickets

  def self.search(param)
    return all unless param
    return none unless param.size > 2

    search_names_and_locations(param)
  end
end
