# frozen_string_literal: true

class LotteryDivision < ApplicationRecord
  include CapitalizeAttributes

  belongs_to :lottery, touch: true
  has_many :entrants, class_name: "LotteryEntrant", dependent: :destroy
  has_many :tickets, through: :entrants

  strip_attributes collapse_spaces: true
  capitalize_attributes :name

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :lottery
end
