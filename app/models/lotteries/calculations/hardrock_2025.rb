# frozen_string_literal: true

class Lotteries::Calculations::Hardrock2025 < ApplicationRecord
  self.table_name = :lotteries_calculations_hardrock_2025s

  enum gender: {
    male: 0,
    female: 1,
    nonbinary: 2,
  }

  belongs_to :organization
  belongs_to :person
end
