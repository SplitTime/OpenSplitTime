# frozen_string_literal: true

class LotteryEntrantParameters < BaseParameters
  def self.mapping
    lottery_entrant_mapping = {
      tickets: :number_of_tickets,
      :"#_of_tickets" => :number_of_tickets,
      :"#_tickets" => :number_of_tickets,
    }

    ::EffortParameters.mapping.merge(lottery_entrant_mapping)
  end

  def self.permitted
    [
      :birthdate,
      :city,
      :country_code,
      :division,
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
