# frozen_string_literal: true

class Lotteries::Calculations::Hardrock2025 < ApplicationRecord
  self.table_name = :lotteries_calculations_hardrock_2025s

  belongs_to :organization
  belongs_to :person
end
