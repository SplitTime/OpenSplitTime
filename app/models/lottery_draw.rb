class LotteryDraw < ApplicationRecord
  include PersonalInfo

  belongs_to :lottery
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id

  scope :with_entrant_attributes, -> { from(select("lottery_draws.*, lottery_divisions.name as division_name, first_name, last_name, gender, birthdate, city, state_code, state_name, country_code, country_name").joins(ticket: {entrant: :division}), :lottery_draws) }

  attribute :gender
  enum gender: [:male, :female]
end
