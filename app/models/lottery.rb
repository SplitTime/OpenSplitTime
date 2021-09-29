# frozen_string_literal: true

class Lottery < ApplicationRecord
  extend FriendlyId
  include CapitalizeAttributes

  belongs_to :organization

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
  friendly_id :name, use: [:slugged, :history]

  validates_presence_of :name, :scheduled_start_date
  validates_uniqueness_of :name, case_sensitive: false, scope: :organization
end
