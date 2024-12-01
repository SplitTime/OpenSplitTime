# frozen_string_literal: true

class Lotteries::Calculations::Hardrock2025 < ApplicationRecord
  self.table_name = :lottery_ticket_calc_hardrock_2025s

  belongs_to :organization
  belongs_to :person
end
