class HistoricalFact < ApplicationRecord
  enum kind: {
    dns: 0,
    dnf: 9,
    finished: 10,
    lottery_application: 11,
    volunteer_year: 1,
    volunteer_year_major: 2,
    volunteer_multi: 3,
    volunteer_multi_reported: 14,
    volunteer_hours: 17,
    trail_work_hours: 18,
    qualifier_finish: 4,
    emergency_contact: 5,
    previous_email: 15,
    previous_name: 6,
    ever_finished: 12,
    dns_since_finish: 13,
    lottery_ticket_count_legacy: 7,
    lottery_division_legacy: 8,
    ticket_reset_legacy: 16,
  }

  include Auditable
  include CapitalizeAttributes
  include Matchable
  include PersonalInfo
  include Searchable
  include StateCountrySyncable

  strip_attributes collapse_spaces: true
  strip_attributes only: [:phone, :emergency_phone], regex: /[^0-9|+]/
  capitalize_attributes :first_name, :last_name, :city, :emergency_contact
  has_paper_trail

  belongs_to :organization
  belongs_to :person, optional: true

  attr_writer :creator

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :gender, presence: true
  validates :kind, presence: true


  before_save :fill_personal_info_hash

  scope :by_kind, ->(kinds) { where(kind: kinds) if kinds.present? }
  scope :by_reconciled, ->(reconciled_boolean) do
    if reconciled_boolean == true
      where.not(person_id: nil)
    elsif reconciled_boolean == false
      where(person_id: nil)
    else
      all
    end
  end
  scope :ordered, -> { order(:last_name, :first_name, :state_code, :year, :kind) }
  scope :ordered_within_person, -> { order(:year, :kind) }
  scope :reconciled, -> { where.not(person_id: nil) }
  scope :unreconciled, -> { where(person_id: nil) }

  def self.search(search_text)
    return all unless search_text.present?

    search_names_and_locations(search_text)
  end

  def creator
    return @creator if defined?(@creator)

    @creator = User.find_by(id: created_by) if created_by?
  end

  def related_facts
    organization.historical_facts.where(personal_info_hash: personal_info_hash)
  end

  def reconciled?
    person_id.present?
  end

  def unreconciled?
    !reconciled?
  end

  private

  # Needed to keep PersonalInfo#bio from breaking
  def current_age_approximate
    nil
  end

  def fill_personal_info_hash
    string = [first_name, last_name, gender, birthdate, state_code].compact.join(",")
    self.personal_info_hash = Digest::MD5.hexdigest(string)
  end
end
