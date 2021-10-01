# frozen_string_literal: true

class Lottery < ApplicationRecord
  extend FriendlyId
  include CapitalizeAttributes, Delegable

  belongs_to :organization
  has_many :divisions, class_name: "LotteryDivision", dependent: :destroy
  has_many :entrants, through: :divisions
  has_many :tickets, class_name: "LotteryTicket", dependent: :destroy

  strip_attributes collapse_spaces: true
  capitalize_attributes :name
  friendly_id :name, use: [:slugged, :history]

  validates_presence_of :name, :scheduled_start_date
  validates_uniqueness_of :name, case_sensitive: false, scope: :organization

  scope :with_policy_scope_attributes, -> do
    from(select("lotteries.*, organizations.concealed").joins(:organization), :lotteries)
  end

  def generate_ticket_hashes(beginning_reference_number: 100000)
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

  def delete_and_insert_tickets(beginning_reference_number: 100000)
    tickets.delete_all

    ticket_hashes = generate_ticket_hashes(beginning_reference_number: beginning_reference_number)
    LotteryTicket.insert_all(ticket_hashes)
  end
end
