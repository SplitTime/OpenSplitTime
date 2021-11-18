# frozen_string_literal: true

class Lottery < ApplicationRecord
  extend FriendlyId
  include CapitalizeAttributes, Concealable, Delegable

  belongs_to :organization
  has_many :divisions, class_name: "LotteryDivision", dependent: :destroy
  has_many :entrants, through: :divisions
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy
  has_many :draws, class_name: "LotteryDraw", dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
  friendly_id :name, use: [:slugged, :history]

  attribute :concealed, default: -> { true }
  enum status: [:preview, :live, :finished], _default: :preview

  validates_presence_of :name, :scheduled_start_date
  validates_uniqueness_of :name, case_sensitive: false, scope: :organization

  scope :with_policy_scope_attributes, -> do
    from(select("lotteries.*, organizations.concealed").joins(:organization), :lotteries)
  end

  def create_draw_for_ticket!(ticket)
    return if ticket.nil? || ticket.drawn?

    draw = draws.create!(ticket: ticket)

    # Touch needs to happen after the draw is created, otherwise
    # the division information will not be up to date when broadcast
    ticket.entrant.division.touch
    draw
  end

  def generate_entrants!
    divisions.each do |division|
      entrant_count = rand(10) + 5

      entrant_count.times do
        attributes = {
          first_name: FFaker::Name.first_name,
          last_name: FFaker::Name.last_name,
          gender: [:male, :female].sample,
          birthdate: 65.years.ago.to_date + rand(45 * 365),
          city: FFaker::AddressUS.city,
          state_code: FFaker::AddressUS.state_abbr,
          country_code: "US",
          number_of_tickets: rand(10) + 1,
        }

        division.entrants.create!(attributes)
      end
    end
  end

  def generate_ticket_hashes(beginning_reference_number: 10_000)
    entrant_structs = entrants.struct_pluck(:id, :number_of_tickets)

    ticket_hashes = entrant_structs.flat_map do |struct|
      Array.new(struct.number_of_tickets) do
        {
          lottery_id: id,
          lottery_entrant_id: struct.id,
          created_at: Time.current,
          updated_at: Time.current,
        }
      end
    end

    ticket_hashes.shuffle!
    ticket_hashes.each_with_index do |ticket_hash, i|
      ticket_hash[:reference_number] = beginning_reference_number + i
    end

    ticket_hashes
  end

  def delete_and_insert_tickets!(beginning_reference_number: 10_000)
    draws.delete_all
    tickets.delete_all

    ticket_hashes = generate_ticket_hashes(beginning_reference_number: beginning_reference_number)
    LotteryTicket.insert_all(ticket_hashes)
  end
end
