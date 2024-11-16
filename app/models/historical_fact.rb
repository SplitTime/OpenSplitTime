# frozen_string_literal: true

class HistoricalFact < ApplicationRecord
  enum gender: {
    male: 0,
    female: 1,
    nonbinary: 2,
  }

  enum kind: {
    dns: 0,
    volunteer_minor: 1,
    volunteer_major: 2,
    volunteer_legacy: 3,
    reported_qualifier_finish: 4,
    provided_emergency_contact: 5,
    provided_previous_name: 6,
    lottery_ticket_count_legacy: 7,
    lottery_division_legacy: 8,
  }

  include Auditable
  include CapitalizeAttributes

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone, :emergency_phone], regex: /[^0-9|+]/
  capitalize_attributes :first_name, :last_name, :city, :emergency_contact

  belongs_to :organization
  belongs_to :person, optional: true
  belongs_to :event, optional: true
end
