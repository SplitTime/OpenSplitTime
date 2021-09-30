# frozen_string_literal: true

class Lottery < ApplicationRecord
  extend FriendlyId
  include CapitalizeAttributes, Delegable

  belongs_to :organization
  has_many :lottery_divisions, dependent: :destroy
  has_many :lottery_entrants, through: :lottery_divisions

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
  friendly_id :name, use: [:slugged, :history]

  validates_presence_of :name, :scheduled_start_date
  validates_uniqueness_of :name, case_sensitive: false, scope: :organization

  scope :with_policy_scope_attributes, -> do
    from(select("lotteries.*, organizations.concealed").joins(:organization), :lotteries)
  end
end
