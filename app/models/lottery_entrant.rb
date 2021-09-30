# frozen_string_literal: true

class LotteryEntrant < ApplicationRecord
  include CapitalizeAttributes

  belongs_to :lottery_division

  strip_attributes collapse_spaces: true
  capitalize_attributes :first_name, :last_name, :city

  scope :with_division_name, -> { from(select("lottery_entrants.*, lottery_divisions.name as division_name").joins(:lottery_division), :lottery_entrants) }
end
