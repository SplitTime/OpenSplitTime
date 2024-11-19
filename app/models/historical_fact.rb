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
    dnf: 9,
    finished: 10,
  }

  include Auditable
  include CapitalizeAttributes
  include Matchable
  include PersonalInfo
  include Searchable

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone, :emergency_phone], regex: /[^0-9|+]/
  capitalize_attributes :first_name, :last_name, :city, :emergency_contact

  belongs_to :organization
  belongs_to :person, optional: true
  belongs_to :event, optional: true

  attr_writer :creator

  scope :unreconciled, -> { where(person_id: nil) }

  def self.search(search_text)
    return all unless search_text.present?

    search_names_and_locations(search_text)
  end

  def creator
    return @creator if defined?(@creator)

    @creator = User.find_by(id: created_by) if created_by?
  end

  def reconciled?
    person_id.present?
  end

  def unreconciled?
    !reconciled?
  end
end
