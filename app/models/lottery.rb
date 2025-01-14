class Lottery < ApplicationRecord
  extend FriendlyId
  include Delegable
  include Concealable
  include CapitalizeAttributes
  include Partnerable

  belongs_to :organization
  has_many :divisions, class_name: "LotteryDivision", dependent: :destroy
  has_many :entrants, through: :divisions
  has_many :entrant_service_details, through: :entrants, class_name: "Lotteries::EntrantServiceDetail", source: :service_detail
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy
  has_many :simulation_runs, class_name: "LotterySimulationRun", dependent: :destroy

  has_one_attached :service_form

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
  friendly_id :name, use: [:slugged, :history]

  attribute :concealed, default: -> { true }
  enum status: [:preview, :live, :finished], _default: :preview

  validates_presence_of :name, :scheduled_start_date
  validates_uniqueness_of :name, case_sensitive: false, scope: :organization

  scope :with_policy_scope_attributes, -> { all }

  def delete_all_draws!
    draws.delete_all
  end

  # Cannot create this relationship using has_many because Rails gives a
  # ActiveRecord::HasManyThroughCantAssociateThroughHasOneOrManyReflection
  def draws
    LotteryDraw.where(division: divisions)
  end

  def generate_entrants!
    divisions.each do |division|
      entrant_count = rand(5..14)

      entrant_count.times do
        attributes = {
          first_name: FFaker::Name.first_name,
          last_name: FFaker::Name.last_name,
          gender: [:male, :female].sample,
          birthdate: 65.years.ago.to_date + rand(45 * 365),
          city: FFaker::AddressUS.city,
          state_code: FFaker::AddressUS.state_abbr,
          country_code: "US",
          number_of_tickets: rand(1..10)
        }

        division.entrants.create!(attributes)
      end
    end
  end

  def delete_and_insert_tickets!(beginning_reference_number: 10_000)
    delete_all_draws!
    tickets.delete_all

    sql = LotteryTicketQuery.insert_lottery_tickets
    sanitized_sql = ActiveRecord::Base.sanitize_sql([sql, { lottery_id: id, beginning_reference_number: beginning_reference_number }])
    ActiveRecord::Base.connection.execute(sanitized_sql, "LotteryTicket Bulk Insert")
  end

  def start_time
    scheduled_start_date&.in_time_zone("UTC")
  end

  def ticket_calculations
    return unless calculations_available?

    calculation_class_full.all
  end

  def calculations_available?
    calculation_class_full.present?
  end

  def calculation_class_full
    "Lotteries::Calculations::#{calculation_class}".safe_constantize
  end
end
