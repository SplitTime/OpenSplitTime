# frozen_string_literal: true

class LotteryDraw < ApplicationRecord
  include PersonalInfo

  broadcasts_to :lottery

  belongs_to :lottery
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id

  scope :with_entrant_attributes, -> { from(select("lottery_draws.*, lottery_divisions.name as division_name, first_name, last_name, gender, birthdate, city, state_code, state_name, country_code, country_name").joins(ticket: {entrant: :division}), :lottery_draws) }

  attribute :gender
  enum gender: [:male, :female]

  delegate :first_name, :last_name, :birthdate, :city, :state_code, :state_name, :country_code, :country_name,
           to: :entrant
  delegate :entrant, to: :ticket
  delegate :division, to: :entrant

  def division_name
    division.name
  end
end
