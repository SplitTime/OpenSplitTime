# frozen_string_literal: true

class LotteryEntrantParameters < BaseParameters
  def self.permitted
    [
      :birthdate,
      :city,
      :country_code,
      :division_name,
      :first_name,
      :gender,
      :id,
      :last_name,
      :lottery_division_id,
      :number_of_tickets,
      :pre_selected,
      :state_code,
    ]
  end
end
