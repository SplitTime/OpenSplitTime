class Lotteries::Calculations::Hilo2025 < Lotteries::Calculations::Base
  # self.table_name must be set for a Lotteries::Calculations class to work
  self.table_name = :lotteries_calculations_hilo_2025s

  # self.primary_key must be set to :id for PgSearch to work
  # Also, the view must return an "id" column
  # Use select row_number() over () as id if no other unique id is available
  self.primary_key = :id
end
