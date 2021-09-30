# frozen_string_literal: true

class LotteryDivision < ApplicationRecord
  include CapitalizeAttributes

  belongs_to :lottery, touch: true
  has_many :lottery_entrants, dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
end
